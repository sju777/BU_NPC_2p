clearvars; close all; clc; warning off backtrace;
addpath(genpath('/projectnb/npcr25/projects/two_photon/matlab_code/bfmatlab701'))
dbstop if error
%%
%% Folder
commonFolders(1).home='/projectnb2/npcr25/projects/two_photon/';

%% Select File

[listEntry.fileIn,listEntry.folderIn]=uigetfile('*.tif','Select a movie file!',commonFolders(1).home);

%% Data import

%Prepare folder info
listEntry.processed=fullfile(fileparts(listEntry.folderIn),'processed');
listEntry.dilOut=[listEntry.processed,filesep,listEntry.fileIn,'_dil.mat'];
tmpOMEdirPrep=dir([listEntry.folderIn filesep listEntry.fileIn]);
if size(tmpOMEdirPrep,1)
    tmpOME.name=tmpOMEdirPrep(1).name;
    tmpOME.file=fullfile(listEntry.folderIn,tmpOMEdirPrep(1).name);
end
listEntry.ome=tmpOME;
clearvars tmp*

%Check if folder for processed data already exists for this run
listEntry.savepath=fullfile(listEntry.processed,listEntry.fileIn(1:end-4));
if ~exist(listEntry.savepath,"dir")
    mkdir(listEntry.savepath)
else
    fprintf('\nProcessed directory already exists!\n[%s]\n',listEntry.savepath)
end

%Prepare for Suite2p
% clearvars s2pIn
% s2pIn.folderIn=listEntry.folderIn;
% s2pIn.run=listEntry.fileIn;
% s2pIn.save_path=fullfile(listEntry.processed,listEntry.fileIn(1:end-4));
% if ~isfolder(s2pIn.save_path)
%     mkdir(s2pIn.save_path)
% end
% listEntry.s2pIn=s2pIn;

%%
[metadata,~,dataIn]=f_OME_Reader_Wrapper(listEntry.ome.file);

sizeC=metadata.sizeC;
sizeT=metadata.sizeT;
sizeX=metadata.sizeX;
sizeY=metadata.sizeY;
sizeZ=metadata.sizeZ;

dil.selectedChannel='ChA';
dil.filename=listEntry.dilOut;

dataIn=squeeze(dataIn(1,1,:,:,:));
dataIn=permute(dataIn,[2 3 1]);
figure;
set(gcf,'PaperUnits','inches','Units','inches','PaperOrientation','Portrait','PaperPositionMode','manual');
[prn.A] = get(gcf,'Position');
[prn.screen]=get(0,'screensize');
prn.papersize = get(gcf, 'PaperSize');
prn.width=10.5;
prn.height=8;
prn.left = (prn.papersize(1)- prn.width)/2;
prn.bottom = (prn.papersize(2)- prn.height)/2;
set(gcf,'PaperPosition',[prn.left prn.bottom prn.width prn.height]);
%set(gcf,'Position',[prn.A(1) prn.A(2) prn.width prn.height]);
movegui('center')

% Calculates the MIP image over time. User selects a rectangle (only
% containing background, not vessel). Rectangle should be going from
% top to bottom as far as possilbe to reduce Optogen artifact as much
% as possible. Image gets corrected for background (for every frame,
% them average intensity of the background region is subtracted from all
% pixels).

subplot(4,3,1);
imagesc(max(dataIn,[],3));axis image off;colorbar;
title('MIP; draw rectangle for bg correction!')
notDone=1;
while (notDone)
    tmpBgRegion=getrect;
    tmpX=[floor(tmpBgRegion(1)):(floor(tmpBgRegion(1))+ceil(tmpBgRegion(3)))];
    tmpY=[floor(tmpBgRegion(2)):(floor(tmpBgRegion(2))+ceil(tmpBgRegion(4)))];
    if tmpX(1)<1 || tmpX(end)>size(dataIn,2) || tmpY(1)<1 || tmpY(end)>size(dataIn,1)
        f = msgbox('Rectangle outside image! Try again!','Error!','warn');
        waitfor(f);
    else
        dil.roi.bg.X=tmpX;
        dil.roi.bg.Y=tmpY;
        notDone=0;
    end
end
rectangle('Position',tmpBgRegion,'EdgeColor', [1 1 1]);
title('MIP / bg')



%dil.roi.bg.X=[floor(tmpBgRegion(1)):(floor(tmpBgRegion(1))+ceil(tmpBgRegion(3)))];
%dil.roi.bg.Y=[floor(tmpBgRegion(2)):(floor(tmpBgRegion(2))+ceil(tmpBgRegion(4)))];



timeSeriesBg=zeros(size(dataIn));
for iFrame=1:size(dataIn,3)
    timeSeriesBg(:,:,iFrame)=dataIn(:,:,iFrame)-nanmean(nanmean(dataIn(dil.roi.bg.Y,dil.roi.bg.X,iFrame)));
end
refImage=nanmean(timeSeriesBg,3);

%% Generates the reference image to select intensity for binary mask.
notDone=1;
iROI=1;
while (notDone)
    clear tmp*
    subplot(4,3,2);imagesc(refImage);axis image off;colorbar; title('Select ROI (right-click: whole image is ROI)');hold all;
    [dil.roi.vessel(iROI).X,dil.roi.vessel(iROI).Y] = getline('closed');
    if iROI==1 && max(dil.roi.vessel(iROI).X)==min(dil.roi.vessel(iROI).X) && max(dil.roi.vessel(iROI).Y)==min(dil.roi.vessel(iROI).Y)
        wholeROI=1;
        dil.roi.vessel(iROI).Y=[1 size(timeSeriesBg,1) size(timeSeriesBg,1) 1 1];
        dil.roi.vessel(iROI).X=[1 1 size(timeSeriesBg,2) size(timeSeriesBg,2) 1];
        dil.roi.vessel(iROI).mask=true(size(timeSeriesBg,1),size(timeSeriesBg,2));
        tmpRefImageROI=refImage.*dil.roi.vessel(iROI).mask;
    else
        wholeROI=0;
        plot(dil.roi.vessel(iROI).X,dil.roi.vessel(iROI).Y);
        dil.roi.vessel(iROI).centerX=min(dil.roi.vessel(iROI).X)+(max(dil.roi.vessel(iROI).X)-min(dil.roi.vessel(iROI).X))/2;
        dil.roi.vessel(iROI).centerY=min(dil.roi.vessel(iROI).Y)+(max(dil.roi.vessel(iROI).Y)-min(dil.roi.vessel(iROI).Y))/2;
        text(dil.roi.vessel(iROI).centerX,dil.roi.vessel(iROI).centerY,num2str(iROI),'FontSize',12, 'Color', [1 1 1])
        dil.roi.vessel(iROI).nx=size(timeSeriesBg,1);
        dil.roi.vessel(iROI).ny=size(timeSeriesBg,2);
        dil.roi.vessel(iROI).mask=poly2mask(dil.roi.vessel(iROI).X,dil.roi.vessel(iROI).Y,dil.roi.vessel(iROI).nx,dil.roi.vessel(iROI).ny);
        tmpRefImageROI=refImage.*dil.roi.vessel(iROI).mask;
    end
    title('Average and ROIs');
    
    subplot(4,3,[4:5]);
    tmpRefImageReshape=reshape(double(tmpRefImageROI),1,size(tmpRefImageROI,1)*size(tmpRefImageROI,2));
    [tmpElements,~]=hist(tmpRefImageReshape);
    hist(tmpRefImageReshape);
    title('Select intensity threshold...')
    [dil.threshold(iROI),~]=ginput(1);
    line([dil.threshold(iROI) dil.threshold(iROI)],[0 max(tmpElements)], 'Color', [1 0 0]);
    title('Intensity threshold')
    
    subplot(4,3,3);imagesc(refImage>dil.threshold(iROI));axis image off;colorbar;title('Average threshold');
    [tmpRows,tmpCols]=find(tmpRefImageROI>dil.threshold(iROI));
    tmpHistImage=zeros(size(timeSeriesBg,1),size(timeSeriesBg,2));
    for j=1:length(tmpRows)
        tmpHistImage(tmpRows(j),tmpCols(j))=1;
    end
    tmpTimecourse=zeros(size(timeSeriesBg,3),1);
    for j=1:size(timeSeriesBg,3)
        timeSeriesBgReshape=reshape(timeSeriesBg(:,:,j).*dil.roi.vessel(iROI).mask,1,size(timeSeriesBg,1)*size(timeSeriesBg,2));
        tmpTimecourse(j)=1/(size(timeSeriesBg,1)*size(timeSeriesBg,2))*length(find(timeSeriesBgReshape>dil.threshold(iROI)));
    end
    dil.timecourse(iROI).t=1:size(timeSeriesBg,3);
    dil.timecourse(iROI).area=tmpTimecourse;
    dil.timecourse(iROI).areaNorm=(dil.timecourse(iROI).area-mean(dil.timecourse(iROI).area))/mean(dil.timecourse(iROI).area);
    dil.timecourse(iROI).dia=sqrt(tmpTimecourse);
    dil.timecourse(iROI).diaNorm=(dil.timecourse(iROI).dia-mean(dil.timecourse(iROI).dia))/mean(dil.timecourse(iROI).dia);
    
    subplot(4,3,[7:9]);hold on
    plot(dil.timecourse(iROI).t,dil.timecourse(iROI).areaNorm);
    %for iFrame=1:size(diag.artifact.frames,2)
    %    plot(dil.timecourse(iROI).t(diag.artifact.frames(iFrame)),dil.timecourse(iROI).areaNorm(diag.artifact.frames(iFrame)),'or');
    %    plot(dil.timecourse(iROI).t(diag.artifact.frames(iFrame)),[1.05*max(dil.timecourse(iROI).areaNorm) 1.05*max(dil.timecourse(iROI).areaNorm)],'xr');
    %end
    title('Timecourse (area A)');%xlabel('time [s]');
    ylabel('\DeltaA/A');axis tight;
        
    subplot(4,3,[10:12]);hold on
    plot(dil.timecourse(iROI).t,dil.timecourse(iROI).diaNorm);
    %for iFrame=1:size(diag.artifact.frames,2)
    %    plot(dil.timecourse(iROI).t(diag.artifact.frames(iFrame)),dil.timecourse(iROI).diaNorm(diag.artifact.frames(iFrame)),'or');
    %    plot(dil.timecourse(iROI).t(diag.artifact.frames(iFrame)),[1.05*max(dil.timecourse(iROI).diaNorm) 1.05*max(dil.timecourse(iROI).diaNorm)],'xr');
    %end
    title('Timecourse (\surd(A)');xlabel('time [s]');ylabel('\Delta\surdA/\surdA');axis tight;
    
    %subtitle(['Dilation: ' dir0.pathname]);
    
    if wholeROI
        notDone=0;
    else
        tmpQ = questdlg('Analyze another region?','Continue Operation','Yes','No','Yes');
        if strcmp(tmpQ,'No')
            notDone = 0;
        end
        iROI=iROI+1;
    end
end
%% Saves overview image to .png file
%print(gcf, '-dpng', [dir0.images filesep 'dil_run' num2str(dir0.runnum)]);
%print(gcf, '-depsc2', [dir0.images filesep 'dil_run' num2str(dir0.runnum)]);

%% Saves estimated parameters to .mat file
%disp(['saved under ' dir0.processed filesep 'dil_run' num2str(dir0.runnum)])
save(listEntry.dilOut,'dil');
            