%% Prepare workspace
clearvars; clc; %daqreset;

% Based on script_MTH_Stim_Main_BlockGUI.m.
% Adds a 'trialTrigger' output on a digital line (device.outputChannel(3),
% see "Analog/Digital Output channels" below) whose pulse-train duration
% is regenerated per trial type from 'trialType(iType).triggerDuration'
% (see "Build per-trial-type waveforms"), so the trial type can be
% decoded post-hoc from the width of the trigger pulse train in the
% recording, independent of the audio/airpuff channels themselves. For
% that decoding to actually work, physically wire the digital output
% (port0/line0 by default) to the 'trialTrigger' analog input
% (device.inputChannel(1), ai1) so the pulse train ends up in the saved
% analogInput data.
%
% Adds a GUI (below, under "Design stimulus block") to set the number of
% trials in a block, randomly assign 80% of trials as paired
% (airpuff+audio), 10% as airpuff-only, and 10% as audio-only, preview the
% resulting sequence as a colored strip (blue = airpuff, red = audio,
% purple = paired), hand-edit any individual trial's type in a table, and
% save/load named presets of the block design.

% Current Setting TS21 organoid mice:
% Amplitude 1.8 V; duration: 5s; ISI 10 s
% 10% duty cycle; 30 trials for stim after 120 s baseline
% rs (resting state run) with 600 s, then 10 trails with 5-20 Hz (last
% run!)6
% Stim frequencues: 2, 5, 10, 20, 40 Hz
% Total number of runs: 6 (5 stim + 1 baseline)
% Basler input line 3♦ on Intan sample clock - trigger when ephys data is
% being recorded; limit acquisition frequency to 20 Hz (align images across
% t axis for the ephys recording)

%% Folder
% Filename will be generated as 'root\date\animal\trigger\Run00X_info.mat'
folder.root='C:\Data\test1';
folder.date='26-08-02';     % (use YY-MM-DD)
folder.animal='test1';
folder.run= 1; % (needs to be a number)
folder.info='test';

%% Define trials and record duration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% |
% | preTrialRecordTime (in s)
% |
% | %%%%%%%%% N repetitions %%%%%%%%%%%%
% | %  Trial length: ISI (in s)        %
% | %  Contains stimulus sequences,    %
% | %  trial type varies per rep       %
% | %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% |
% | postTrialRecordTime (in s)
% |
%\|/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trial.N is set by the block design GUI below (not fixed here).
trial.ISI=5;% (in s) %20 long 5Hz,30sec
    %ephys: 10
trial.backgroundTime=5;%20 long 5Hz,30sec
    %ephys: 120, 600
trial.postTrialRecordTime=0;% (in s) Extra recording
%time after last trial %20 long 5Hz,30sec

%% Define trial types (airpuff-only / audio-only / paired stimulation)
% Each trial type lists which stimuli (by 'stimulus.name', defined below)
% are delivered on that trial. The 'paired' type activates both 'airpuff'
% and 'audio' together. The '.color' field is used by the block design
% GUI to draw the colored preview and the manual-edit table. The
% 'trialTrigger' output (see device.outputChannel below) is present on
% every trial regardless of type, but '.triggerDuration' sets how long
% its pulse train runs on that trial type - so the trial type can be
% read back from the trigger channel alone during analysis.
trialType(1).name='airpuff';
trialType(1).activeStimuli={'airpuff'};
trialType(1).color=[0.15 0.35 0.85];           % blue
trialType(1).triggerDuration=0.2;              % (in s)
trialType(2).name='audio';
trialType(2).activeStimuli={'audio'};
trialType(2).color=[0.85 0.15 0.15];           % red
trialType(2).triggerDuration=0.4;              % (in s)
trialType(3).name='paired';
trialType(3).activeStimuli={'airpuff','audio'};
trialType(3).color=[0.55 0.15 0.65];           % purple
trialType(3).triggerDuration=0.6;              % (in s)

%% Design stimulus block via GUI
% Set the number of trials per block, then randomly assign 80% of trials
% as 'paired' (airpuff+audio), 10% as 'airpuff' only, and 10% as 'audio'
% only. The sequence is previewed as a colored strip and listed in an
% editable table (blue = airpuff, red = audio, purple = paired) - change
% the "Type" column of any row to hand-override that trial. Save/load
% named presets of the block (trial count + per-trial type sequence) via
% the Preset controls. Click "Use This Block" to accept the sequence and
% continue the script.
[trial.N, trial.labels] = designStimBlockGUI(trialType, 30);
if trial.N==0
    fprintf('\nBlock design cancelled by user. Aborting.\n');
    return
end
[~,trial.order]=ismember(trial.labels,{trialType.name}); % numeric index into trialType

% Derived from previous parameters
run.tTotal=trial.backgroundTime+trial.N*trial.ISI+trial.postTrialRecordTime;

%% Define stimulus parameters
% Stimuli are defined per Analog Output Channel (ao0, ao1, ao2, ...)
% The number of stimuli must match number of Analog Output Channels!
% The variable 'stimulus.name' must match 'device.outputChannel.name'!

% OPTION: rect
%                           <--------------- duration -------------->
%           amplitude ->     -------         -------         -------
%                           |<width>|       |       |       |       |
%           delay           |       |       |       |       |       |
% ---------------------------       ---------       ---------       -------
%
% 'trialTrigger' ends up as a single continuous HIGH pulse per trial (not
% a multi-pulse train like 'rect' above) - its WIDTH is what encodes
% trial type, via trialType(iType).triggerDuration and generateSinglePulse
% (see "Build per-trial-type waveforms" below). 'pulseWidth'/'frequency'/
% 'duration' below only build the placeholder single-trial template in
% this section, which is fully overwritten per trial type further down -
% they're irrelevant to the actual output.
stimulus(3).name='trialTrigger';
stimulus(3).type='rect';                % options: rect
stimulus(3).delay=0;                    % delay (in s) from trial start to first pulse
stimulus(3).pulseWidth=10e-3;           % width (in s) of individual pulses (placeholder only)
stimulus(3).frequency=1;                % frequency (in Hz) of pulse train (placeholder only)
stimulus(3).duration=1;                 % duration of pulse train (placeholder only)
stimulus(3).amplitude=1;                % logical level (1=high) - this channel is
                                         % a Digital output (port0/line0), not Voltage

stimulus(2).name='airpuff';
stimulus(2).type='rect';
stimulus(2).delay=1;
stimulus(2).pulseWidth=10e-3;           % (in s)
stimulus(2).frequency=3;                % (in Hz)
stimulus(2).duration=2;                 % (in s)
stimulus(2).amplitude=5;                % (in V)


% stimulus(1).name='audio';
% stimulus(1).type='tone';
% stimulus(1).delay=0;
% %stimulus(1).pulseWidth=10e-3;           % (in s)
% stimulus(1).frequency=12000;                % (in Hz)
% stimulus(1).duration=2;                 % (in s)
% stimulus(1).amplitude=5;                % (in V)

stimulus(1).name='audio';
stimulus(1).type='tone';                % options: rect, tone
stimulus(1).delay=0;                    % delay (in s) from trial start to tone onset
stimulus(1).toneFrequency=12000;        % carrier frequency (in Hz) of the tone
stimulus(1).duration=1;               % duration (in s) of the tone
stimulus(1).amplitude=5;                % amplitude (in V) of the tone
stimulus(1).rampTime=0;              % (in s) linear on/off ramp to avoid clicks


%% DAQ device
device.manufacturer='ni';
device.name='Dev1';

%% Analog Input channels
% The variable 'device.inputChannel.id' must be unique and
%   must match the channel name in the device (ai0, ai1, ai2, ...)!
% The variable 'device.inputChannel.name' must be unique!
device.inputRate=30E3;  %(in Hz)
device.inputChannel(1).id='ai1';
device.inputChannel(1).name='trialTrigger';
device.inputChannel(2).id='ai2';
device.inputChannel(2).name='everyFrame';

%% Analog/Digital Output channels
% The variable 'device.outputChannel.id' must be unique!
% The variable 'device.outputChannel.name' must be unique!
% The variable 'device.outputChannel.name' must match 'stimulus.name'!
% The variable 'device.outputChannel.type' selects 'Voltage' (analog
% output) or 'Digital' (Port 0 digital line) for that channel.
% 'trialTrigger' is routed to a Port 0 digital line (adjust the id below
% to match a free digital line on your DAQ card if 'port0/line0' is
% already in use).
device.outputRate=30E3; %(in Hz)
device.outputChannel(1).id='ao0';
device.outputChannel(1).name='audio';
% device.outputChannel(1).type='Voltage';
device.outputChannel(2).id='ao1';
device.outputChannel(2).name='airpuff';
% device.outputChannel(2).type='Voltage';
device.outputChannel(3).id='port0/line0';
device.outputChannel(3).name='trialTrigger';
device.outputChannel(3).type='Digital';


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% No variables need to be changed below here! %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generate stimulus trains
if size(device.outputChannel,2)~=size(stimulus,2)
    error('Define stimulus for every output channel')
end
run.tTrial=(1/device.outputRate:1/device.outputRate:trial.ISI);
run.VTrial=zeros(device.outputRate*trial.ISI,size(device.outputChannel,2));
fprintf('\nBackground Imaging Time Before Stimulus:  %0.0f s', trial.backgroundTime)
fprintf('\nPost-trial recording time:                %0.0f s', trial.postTrialRecordTime)
fprintf('\nNumber of trials:                         %d', trial.N)
fprintf('\nSingle trial duration:                    %0.0f s', trial.ISI)
fprintf('\nTotal recording time:                     %0.0f s...', run.tTotal)
for iStimulus=1:size(stimulus,2)
    tmpInd=find(strcmp({device.outputChannel.name},stimulus(iStimulus).name));
    if ~isempty(tmpInd) && size(tmpInd,2)==1
        switch stimulus(iStimulus).type
            case 'rect'
                tmpStimStart=stimulus(iStimulus).delay*device.outputRate;
                tmpPulseWidth=int32(stimulus(iStimulus).pulseWidth*device.outputRate);
                tmpNPulses=stimulus(iStimulus).frequency*stimulus(iStimulus).duration;
                tmpPulseInterval=floor(device.outputRate/stimulus(iStimulus).frequency);
                for iPulse=1:tmpNPulses
                    tmpPulseStartInd=tmpStimStart+(iPulse-1)*tmpPulseInterval+1;
                    tmpPulseEndInd=tmpStimStart+(iPulse-1)*tmpPulseInterval+tmpPulseWidth;
                    tmpPulseAmplitude=ones(tmpPulseEndInd-tmpPulseStartInd+1,1)*stimulus(iStimulus).amplitude;
                    run.VTrial(tmpPulseStartInd:tmpPulseEndInd,tmpInd)=tmpPulseAmplitude;
                end
                if tmpPulseEndInd>size(run.tTrial,2)
                    error('Stimulus is longer than trial ISI.')
                end
            case 'tone'
                % Audio stimulation: sine-wave tone burst with linear
                % on/off ramp envelope (to avoid audio clicks)
                tmpStimStart=stimulus(iStimulus).delay*device.outputRate+1;
                tmpNSamples=round(stimulus(iStimulus).duration*device.outputRate);
                tmpT=(0:tmpNSamples-1)/device.outputRate;
                %ourOwnPi=long(pi);
                % for iT=1:size(tmpT,2)
                %     tmpTone(iT)=5*sin(5000*tmpT(iT));
                % end
                tmpTone=stimulus(iStimulus).amplitude.*sin(2*3.14*stimulus(iStimulus).toneFrequency.*tmpT)';

                tmpRampSamples=round(stimulus(iStimulus).rampTime*device.outputRate);

                if tmpRampSamples>0
                    tmpRamp=linspace(0,1,tmpRampSamples)';
                    tmpTone(1:tmpRampSamples)=tmpTone(1:tmpRampSamples).*tmpRamp;
                    tmpTone(end-tmpRampSamples+1:end)=tmpTone(end-tmpRampSamples+1:end).*flipud(tmpRamp);
                end
                tmpStimEnd=tmpStimStart+tmpNSamples-1;
                run.VTrial(tmpStimStart:tmpStimEnd,tmpInd)=tmpTone;
                if tmpStimEnd>size(run.tTrial,2)
                    error('Stimulus is longer than trial ISI.')
                end
            otherwise
                error('Unknown stimulus type.')
        end
    else
        error([stimulus(iStimulus).name ' not found in device.outputChannel.name!'])
    end
run.VTrial(end-100:end,tmpInd)=0; % MTH 09/20/21 added to solve problem with airpuff blowing like the big bad wulf
end
clearvars tmp* i*

%% Build per-trial-type waveforms and assemble the block's run sequence
% Each trial type only includes the stimuli listed in
% 'trialType(iType).activeStimuli' (defined above); the other output
% channel stays at 0V for that trial. The 'trialTrigger' channel is
% present on every trial type, but is regenerated here as a single
% continuous pulse whose WIDTH is 'trialType(iType).triggerDuration' (not
% a multi-pulse train - see generateSinglePulse below), so each trial
% type gets its own trigger pulse width. The full run waveform (run.VOut)
% concatenates one ISI-length block per trial, in the order given by
% 'trial.order' (set by the block design GUI above), so airpuff-only,
% audio-only, and paired trials are interleaved within the block.
tmpTriggerInd=find(strcmp({stimulus.name},'trialTrigger'));
tmpTriggerChannelInd=find(strcmp({device.outputChannel.name},'trialTrigger'));

run.VTrialType=cell(1,size(trialType,2));
for iType=1:size(trialType,2)
    tmpV=zeros(size(run.VTrial));
    for iStimulus=1:size(stimulus,2)
        if any(strcmp(trialType(iType).activeStimuli,stimulus(iStimulus).name))
            tmpInd=find(strcmp({device.outputChannel.name},stimulus(iStimulus).name));
            tmpV(:,tmpInd)=run.VTrial(:,tmpInd);
        end
    end
    tmpV(:,tmpTriggerChannelInd)=generateSinglePulse(size(run.VTrial,1),device.outputRate, ...
        stimulus(tmpTriggerInd).delay,trialType(iType).triggerDuration,stimulus(tmpTriggerInd).amplitude);
    run.VTrialType{iType}=tmpV;
end
clearvars tmp*

run.VOut=zeros(device.outputRate*trial.ISI*trial.N,size(device.outputChannel,2));
for iTrial=1:trial.N
    tmpRows=(iTrial-1)*size(run.VTrial,1)+(1:size(run.VTrial,1));
    run.VOut(tmpRows,:)=run.VTrialType{trial.order(iTrial)};
end
clearvars tmp* i*
fprintf('\nTrial type sequence (%s):     %s', strjoin({trialType.name},'/'), mat2str(trial.order))

%% Define file name and check if file already exists.
[~,~,~]=mkdir(fullfile(folder.root,folder.date,folder.animal,'trigger'));
folder.directory = fullfile(folder.root,folder.date,folder.animal,'trigger');
folder.fullfile=fullfile(folder.root,folder.date,folder.animal,'trigger',sprintf('Run%03.0f_%s.mat',folder.run,folder.info));
fprintf('\n\nRecording file name:           %s...', folder.fullfile)
if exist(folder.fullfile,'file')
    fig = uifigure;
    tmpProceed=uiconfirm(fig,sprintf('Overwrite %s?',folder.fullfile),'Target file already exists!','Icon','warning','Options',{'Overwrite','Cancel'},'DefaultOption',2,'CancelOption',2);
    close(fig);clearvars fig
    if ~strcmp(tmpProceed,'Overwrite')
        return;
    else
        fprintf('OVERWRITE');
    end
end
% %% Prepare DAQ system
% fprintf('\n\nPreparing DAQ system...')
% daqreset; clearvars handler*
% tmpInfo=daqlist(device.manufacturer);
% tmpInfo=tmpInfo(1,:)
% tmpInd=find(strcmp({tmpInfo.DeviceInfo.Subsystems.SubsystemType},'AnalogInput'));
% device.info.analogInput.channelNames=tmpInfo.DeviceInfo.Subsystems(tmpInd).ChannelNames;
% tmpInd=find(strcmp({tmpInfo.DeviceInfo.Subsystems.SubsystemType},'AnalogOutput'));
% device.info.analogOutput.channelNames=tmpInfo.DeviceInfo.Subsystems(tmpInd).ChannelNames;
% tmpInd=find(strcmp({tmpInfo.DeviceInfo.Subsystems.SubsystemType},'DigitalIO'));
% device.info.digitalIO.channelNames=tmpInfo.DeviceInfo.Subsystems(tmpInd).ChannelNames;
%
% %% Perform consistency checks
% if size({device.inputChannel.id},2)~=size(unique({device.inputChannel.id}),2)
%     error('Analog Input Channel ID (device.inputChannel.id) must be unique');
% end
% if size({device.inputChannel.name},2)~=size(unique({device.inputChannel.name}),2)
%     error('Analog Input Channel Name (device.inputChannel.name) must be unique');
% end
% if size({device.outputChannel.id},2)~=size(unique({device.outputChannel.id}),2)
%     error('Analog Output Channel ID (device.outputChannel.id) must be unique');
% end
% if size({device.outputChannel.name},2)~=size(unique({device.outputChannel.name}),2)
%     error('Analog Output Channel Name (device.outputChannel.name) must be unique');
% end
%
% %% Check for correct Analog Input Channel and Output Channel assignment
% for iChannel = 1:size(device.inputChannel,2)
%     tmpInd=find(strcmp(device.info.analogInput.channelNames,device.inputChannel(iChannel).id));
%     if isempty(tmpInd)
%         error(['Analog Input Channel with ID ' device.inputChannel(iChannel).id ' is not available on ' device.name])
%     end
% end
% for iChannel = 1:size(device.outputChannel,2)
%     switch device.outputChannel(iChannel).type
%         case 'Voltage'
%             tmpInd=find(strcmp(device.info.analogOutput.channelNames,device.outputChannel(iChannel).id));
%         case 'Digital'
%             tmpInd=find(strcmp(device.info.digitalIO.channelNames,device.outputChannel(iChannel).id));
%         otherwise
%             error('Unknown device.outputChannel.type.')
%     end
%     if isempty(tmpInd)
%         error(['Output Channel with ID ' device.outputChannel(iChannel).id ' is not available on ' device.name])
%     end
% end
% clear tmp*
%
% %% Create Analog Input Handler
% handlerDeviceInput=         daq(device.manufacturer);
% handlerDeviceInput.Rate=    device.inputRate;
% for iChannel=1:size(device.inputChannel,2)
%     [~,device.inputChannelIndex(iChannel)]=addinput(handlerDeviceInput,device.name,device.inputChannel(iChannel).id,"Voltage");
%     handlerDeviceInput.Channels(device.inputChannelIndex(iChannel)).TerminalConfig="SingleEnded";
%     handlerDeviceInput.Channels(device.inputChannelIndex(iChannel)).Name=device.inputChannel(iChannel).name;
% end
%
% %% Create Analog/Digital Output Handler
% handlerDeviceOutput=        daq(device.manufacturer);
% handlerDeviceOutput.Rate =  device.outputRate;
% for iChannel=1:size(device.outputChannel,2)
%     switch device.outputChannel(iChannel).type
%         case 'Voltage'
%             [~,device.outputChannelIndex(iChannel)]=addoutput(handlerDeviceOutput,device.name,device.outputChannel(iChannel).id,"Voltage");
%         case 'Digital'
%             [~,device.outputChannelIndex(iChannel)]=addoutput(handlerDeviceOutput,device.name,device.outputChannel(iChannel).id,"Digital");
%         otherwise
%             error('Unknown device.outputChannel.type.')
%     end
%     handlerDeviceOutput.Channels(device.outputChannelIndex(iChannel)).Name=device.outputChannel(iChannel).name;
% end
%
% %% Load Analog Output to DAQ Card
% preload(handlerDeviceOutput,run.VOut);
% fprintf('done.')
% 
% %%
% clc;
% fprintf('\n *** %s ***',folder.fullfile);
% fprintf('\nBackground Imaging Time Before Airpuff:  %0.0f s', trial.backgroundTime)
% fprintf('\nPost-trial recording time:               %0.0f s', trial.postTrialRecordTime)
% fprintf('\nNumber of trials:                        %d', trial.N)
% fprintf('\nSingle trial duration:                   %0.0f s', trial.ISI)
% fprintf('\nTotal recording time:                    %0.0f s', run.tTotal)
% 
% %% Wait for user input
% fprintf('\n\nPress any key to start run...'); pause
% 
% %% Perform run
% fprintf('\nStarting analog input...')
% start(handlerDeviceInput,"Duration",seconds(run.tTotal+10));
% fprintf('\nPre-trial baseline');
% pause(trial.backgroundTime)
% fprintf('\nTrials...')
% % run.VOut already contains the full block sequence (see 'Build
% % per-trial-type waveforms...' above), so it is played once, not repeated.
% start(handlerDeviceOutput)
% pause(trial.N*trial.ISI)
% stop(handlerDeviceOutput)
% fprintf('\nPost-trial recording time...')
% pause(trial.postTrialRecordTime)
% pause(10);
% fprintf('\nAcquistion finished.')
% %% Load analog input and save into mat file
% fprintf('\nReading analog input and save to file...')
% analogInput = read(handlerDeviceInput,"all");
% save(folder.fullfile,'analogInput','trial','trialType','stimulus','folder','device');
% fprintf('done.')
% fprintf('\nFinished.\n')
% daqreset; clearvars handler*

%% Local functions (waveform helper + block design GUI + presets)
function v = generateSinglePulse(nSamples, outputRate, delay, duration, amplitude)
% Builds a single output channel's waveform (nSamples x 1) consisting of
% one continuous pulse, HIGH for 'duration' seconds starting at 'delay'.
% Used to regenerate the trialTrigger channel per trial type, where the
% pulse WIDTH itself (trialType(iType).triggerDuration) is what encodes
% trial type - a multi-pulse train (as used for 'rect' stimuli like
% airpuff) breaks down here because 'duration' can be under 1 second
% while the pulse-train math assumes at least one full period fits.
v=zeros(nSamples,1);
tmpStartInd=round(delay*outputRate)+1;
tmpEndInd=tmpStartInd+round(duration*outputRate)-1;
if tmpEndInd>nSamples
    error('Stimulus is longer than trial ISI.')
end
v(tmpStartInd:tmpEndInd)=amplitude;
end

function [N, labels] = designStimBlockGUI(trialType, defaultN)
% Opens a GUI to set the block size, randomly assign trial types
% (80% paired / 10% airpuff / 10% audio), hand-edit individual trials in
% a table, preview the sequence as a colored grid, and save/load named
% presets. Blocks (uiwait) until the user clicks "Use This Block" or
% cancels. Returns N=0, labels={} if cancelled.
typeNames={trialType.name};

fig=uifigure('Name','Design Stimulus Block','Position',[80 80 1000 650]);
fig.CloseRequestFcn=@(src,~) cancelBlock(src);

uilabel(fig,'Text','Number of trials in block:','Position',[20 605 190 22]);
nTrialsField=uispinner(fig,'Position',[215 605 90 22],'Limits',[3 500],'Value',defaultN,'Step',1,'RoundFractionalValues','on');
generateButton=uibutton(fig,'push','Text','Generate Block','Position',[315 605 130 22]);
cancelButton=uibutton(fig,'push','Text','Cancel','Position',[750 605 100 22]);
useBlockButton=uibutton(fig,'push','Text','Use This Block','Position',[860 605 120 22],'Enable','off');

blockTable=uitable(fig,'Position',[20 130 300 460], ...
    'ColumnName',{'Trial #','Type'}, ...
    'ColumnEditable',[false true], ...
    'ColumnFormat',{'numeric',typeNames}, ...
    'ColumnWidth',{70,150}, ...
    'RowName',{});

ax=uiaxes(fig,'Position',[340 150 640 440]);
ax.XTick=[]; ax.YTick=[];
box(ax,'on');
title(ax,'Trial sequence preview');

for iType=1:numel(trialType)
    uilabel(fig,'Text',[char(9632) ' ' trialType(iType).name], ...
        'FontColor',trialType(iType).color,'FontWeight','bold', ...
        'Position',[340+(iType-1)*140 100 140 22]);
end

uilabel(fig,'Text','Preset:','Position',[20 55 60 22]);
presetList=uidropdown(fig,'Position',[85 55 220 22],'Items',{'(no presets saved yet)'});
loadPresetButton=uibutton(fig,'push','Text','Load Preset','Position',[315 55 100 22]);
savePresetButton=uibutton(fig,'push','Text','Save Preset','Position',[420 55 100 22]);
deletePresetButton=uibutton(fig,'push','Text','Delete Preset','Position',[525 55 100 22]);

fig.UserData.controls=struct('nTrialsField',nTrialsField,'table',blockTable,'ax',ax, ...
    'useBlockButton',useBlockButton,'presetList',presetList);
fig.UserData.trialType=trialType;
fig.UserData.labels={};
fig.UserData.result=struct('N',0,'labels',{{}});

generateButton.ButtonPushedFcn = @(~,~) generateBlockCallback(fig);
blockTable.CellEditCallback     = @(src,event) blockTableEditCallback(fig,event);
useBlockButton.ButtonPushedFcn  = @(~,~) confirmBlock(fig);
cancelButton.ButtonPushedFcn    = @(~,~) cancelBlock(fig);
savePresetButton.ButtonPushedFcn   = @(~,~) savePresetCallback(fig);
loadPresetButton.ButtonPushedFcn   = @(~,~) loadPresetCallback(fig);
deletePresetButton.ButtonPushedFcn = @(~,~) deletePresetCallback(fig);

refreshPresetList(fig);
generateBlockCallback(fig); % draw an initial randomized block using the default trial count
uiwait(fig);

result=fig.UserData.result;
delete(fig);
N=result.N;
labels=result.labels;
end

function d = presetDir()
% Presets are stored next to this script, in a folder named after it.
[tmpFolder,tmpName]=fileparts(mfilename('fullpath'));
d=fullfile(tmpFolder,[tmpName '_Presets']);
end

function refreshPresetList(fig)
c=fig.UserData.controls;
d=presetDir();
names={};
if exist(d,'dir')
    files=dir(fullfile(d,'*.mat'));
    names=cellfun(@(s) s(1:end-4), {files.name}, 'UniformOutput', false);
end
if isempty(names)
    c.presetList.Items={'(no presets saved yet)'};
    c.presetList.Value=c.presetList.Items{1};
else
    c.presetList.Items=sort(names);
    c.presetList.Value=c.presetList.Items{1};
end
end

function generateBlockCallback(fig)
% Randomly assigns trial types at the target fractions (80% paired, 10%
% airpuff, 10% audio - 'paired' absorbs the rounding remainder so the
% total always equals N), then refreshes the table and preview.
c=fig.UserData.controls;
N=round(c.nTrialsField.Value);

nAirpuff=round(0.1*N);
nAudio=round(0.1*N);
nPaired=N-nAirpuff-nAudio; % remainder absorbed by 'paired', keeps total = N

labels=[repmat({'airpuff'},1,nAirpuff),repmat({'audio'},1,nAudio),repmat({'paired'},1,nPaired)];
labels=labels(randperm(N));

fig.UserData.labels=labels;
populateBlockTable(fig);
drawBlockPreview(fig);
c.useBlockButton.Enable='on';
end

function populateBlockTable(fig)
c=fig.UserData.controls;
labels=fig.UserData.labels;
N=numel(labels);
c.table.Data=[num2cell((1:N)'), labels(:)];
end

function blockTableEditCallback(fig, event)
row=event.Indices(1);
labels=fig.UserData.labels;
labels{row}=event.NewData;
fig.UserData.labels=labels;
drawBlockPreview(fig);
end

function drawBlockPreview(fig)
c=fig.UserData.controls;
trialType=fig.UserData.trialType;
labels=fig.UserData.labels;
typeNames={trialType.name};
colorMap=cat(1,trialType.color);
N=numel(labels);

nCols=min(N,25);
nRows=ceil(N/nCols);
img=ones(nRows,nCols,3); % unused (padding) cells stay white
for iTrial=1:N
    tmpRow=ceil(iTrial/nCols);
    tmpCol=iTrial-(tmpRow-1)*nCols;
    tmpType=find(strcmp(typeNames,labels{iTrial}));
    img(tmpRow,tmpCol,:)=colorMap(tmpType,:);
end

cla(c.ax);
image(c.ax,img);
axis(c.ax,'image');
c.ax.XTick=[]; c.ax.YTick=[];
hold(c.ax,'on');
for iTrial=1:N
    tmpRow=ceil(iTrial/nCols);
    tmpCol=iTrial-(tmpRow-1)*nCols;
    text(c.ax,tmpCol,tmpRow,num2str(iTrial),'HorizontalAlignment','center','Color','w','FontSize',8);
end
hold(c.ax,'off');
nAirpuff=sum(strcmp(labels,'airpuff'));
nAudio=sum(strcmp(labels,'audio'));
nPaired=sum(strcmp(labels,'paired'));
title(c.ax,sprintf('%d trials: %d airpuff, %d audio, %d paired',N,nAirpuff,nAudio,nPaired));
end

function confirmBlock(fig)
fig.UserData.result=struct('N',numel(fig.UserData.labels),'labels',{fig.UserData.labels});
uiresume(fig);
end

function cancelBlock(fig)
fig.UserData.result=struct('N',0,'labels',{{}});
uiresume(fig);
end

function savePresetCallback(fig)
labels=fig.UserData.labels;
if isempty(labels)
    uialert(fig,'Generate a block first.','Nothing to save');
    return
end
answer=inputdlg('Preset name:','Save Preset',1,{'my_block'});
if isempty(answer) || isempty(strtrim(answer{1}))
    return
end
name=regexprep(strtrim(answer{1}),'[^\w\-]','_'); % sanitize for a filename

preset=struct();
preset.N=numel(labels);
preset.labels=labels;

d=presetDir();
if ~exist(d,'dir')
    mkdir(d);
end
save(fullfile(d,[name '.mat']),'-struct','preset');

refreshPresetList(fig);
c=fig.UserData.controls;
if any(strcmp(c.presetList.Items,name))
    c.presetList.Value=name;
end
uialert(fig,sprintf('Saved preset "%s".',name),'Preset saved','Icon','success');
end

function loadPresetCallback(fig)
c=fig.UserData.controls;
name=c.presetList.Value;
if strcmp(name,'(no presets saved yet)')
    uialert(fig,'No preset selected. Use "Save Preset" first.','Cannot load preset','Icon','warning');
    return
end
fpath=fullfile(presetDir(),[name '.mat']);
if ~exist(fpath,'file')
    uialert(fig,sprintf('Preset file not found: %s',fpath),'Cannot load preset','Icon','error');
    refreshPresetList(fig);
    return
end
preset=load(fpath);
if ~isfield(preset,'N') || ~isfield(preset,'labels')
    uialert(fig,'Invalid preset file.','Cannot load preset','Icon','error');
    return
end

c.nTrialsField.Value=preset.N;
fig.UserData.labels=preset.labels;
populateBlockTable(fig);
drawBlockPreview(fig);
c.useBlockButton.Enable='on';
uialert(fig,sprintf('Loaded preset "%s".',name),'Preset loaded','Icon','success');
end

function deletePresetCallback(fig)
c=fig.UserData.controls;
name=c.presetList.Value;
if strcmp(name,'(no presets saved yet)')
    return
end
answer=uiconfirm(fig,sprintf('Delete preset "%s"? This cannot be undone.',name), ...
    'Delete preset','Options',{'Yes','No'},'DefaultOption',2,'CancelOption',2);
if strcmp(answer,'Yes')
    delete(fullfile(presetDir(),[name '.mat']));
    refreshPresetList(fig);
end
end
