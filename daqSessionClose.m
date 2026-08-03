% daqSessionClose closes the data acquisition session
% 
% updated by Mai-Anh Vu, 10/29/18
% updated by Mai-Anh Vu, 06/18/19 to incorporate 2d ball

global session % our global variable to store everything


% clear all sounds
clear sound
% stop acquisition session
stop(session.nidaq.s);

% stop output session 
if isfield(session.nidaq,'s2') 
    % first turn everything off
    outputSingleScan(session.nidaq.s2,session.nidaq.outputZeros);    
    stop(session.nidaq.s2)    
end
% stop other sessions
for i = 3:10
    if isfield(session.nidaq,['s' num2str(i)]) 
        % first turn everything off        
        try
            session.nidaq.(['s' num2str(i)]).queueOutputData(zeros(500,1));
        catch
        end
        stop(session.nidaq.(['s' num2str(i)]))
    end
end
% stop listeners
for i = 1:10
    if isfield(session.nidaq,['lh' num2str(i)])    
        delete(session.nidaq.(['lh' num2str(i)]));
    end
end
fclose(session.temp.fid1); % close backup file

% read in full data
session.temp.fid2 = fopen([session.dataFilename '_backup.txt'],'r');
if size(session.temp.data,1) == 0    
    maxIdx = max(cell2mat(struct2cell(structfun(@(x) max(x(:)), session.nidaqCh,'UniformOutput',false))));
    [session.temp.fulldata,count] = fread(session.temp.fid2,[maxIdx,Inf],'double');
else
    [session.temp.fulldata,count] = fread(session.temp.fid2,[size(session.temp.data,2),Inf],'double');
end
session.temp.fulldata = session.temp.fulldata';
fclose(session.temp.fid2);
