%% Prepare workspace
clearvars; clc; daqreset;

% Based on script_MTH_Stim_Main.m, with an added audio stimulation channel.
% Audio stimulus is a sine-wave tone burst (with a linear ramp envelope
% to avoid onset/offset clicks) driven out an Analog Output channel into
% a speaker/amplifier.
% Trials are interleaved across trial types (whisker-only, audio-only,
% combined whisker+audio) - see 'Define trial types' section below.

%% Folder
% Filename will be generated as 'root\date\animal\trigger\Run00X_info.mat'
folder.root='C:\Data\test';
folder.date='26-07-226';     % (use YY-MM-DD)
folder.animal='test';
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
trial.ISI=15;% (in s)
trial.backgroundTime=30;% (in s)
trial.postTrialRecordTime=0;% (in s) Extra recording time after last trial

%% Define trial types (interleaved whisker / audio / combined stimulation)
% Each trial type lists which stimuli (by 'stimulus.name', defined below)
% are delivered on that trial. 'trialTrigger' is included in every type
% so the external trigger/sync signal is always present on every trial.
% The 'combined' type activates both 'airpuff' (whisker) and 'audioStim'
% (audio) together - i.e. simultaneous multisensory stimulation on that
% trial. Add/remove trial types or change 'activeStimuli' to customize.
trialType(1).name='whisker';
trialType(1).activeStimuli={'trialTrigger','airpuff'};
trialType(2).name='audio';
trialType(2).activeStimuli={'trialTrigger','audioStim'};
trialType(3).name='combined';
trialType(3).activeStimuli={'trialTrigger','airpuff','audioStim'};

trial.typeRepeats=4;   % number of repeats of EACH trial type
trial.N=trial.typeRepeats*size(trialType,2); % total number of trials
trial.order=[];         % randomized trial-type sequence (blocked/balanced:
                        % each block of size(trialType,2) trials contains
                        % one of every type, in random order)
for iRepeat=1:trial.typeRepeats
    trial.order=[trial.order,randperm(size(trialType,2))]; %#ok<AGROW>
end
clearvars iRepeat

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
% OPTION: tone (audio stimulation)
%                           <----------------- duration ------------------>
%           amplitude ->        /------------------------------\
%                              /                                  \
%           delay             / <-rampTime  sine wave @ toneFrequency rampTime-> \
% -------------------------- /                                                    \ --------
% Linear on/off ramps (rampTime) are applied to avoid audio clicks at tone
% onset/offset.
%
stimulus(1).name='trialTrigger';
stimulus(1).type='rect';                % options: rect, tone
stimulus(1).delay=0;                    % delay (in s) from trial start to first pulse
stimulus(1).pulseWidth=10e-3;            % width (in s) of individual pulses
stimulus(1).frequency=1;                % frequency (in Hz) of pulse trail---
stimulus(1).duration=1;                 % duration of pulse train
stimulus(1).amplitude=5;                % amplitude (in V) of individual pulses

stimulus(2).name='airpuff';
stimulus(2).type='rect';
stimulus(2).delay=0;
stimulus(2).pulseWidth=1e-3;           % (in s)
stimulus(2).frequency=3;                % (in Hz)
stimulus(2).duration=2;                 % (in s)
stimulus(2).amplitude=5;                % (in V)

%% Audio stimulation
stimulus(3).name='audioStim';
stimulus(3).type='tone';                % options: rect, tone
stimulus(3).delay=0;                    % delay (in s) from trial start to tone onset
stimulus(3).toneFrequency=10000;        % carrier frequency (in Hz) of the tone
stimulus(3).duration=0.5;               % duration (in s) of the tone
stimulus(3).amplitude=1;                % amplitude (in V) of the tone
stimulus(3).rampTime=5e-3;              % (in s) linear on/off ramp to avoid clicks

%% DAQ device
device.manufacturer='ni';
device.name='Dev1';

%% Analog Input channels
% The variable 'device.inputChannel.id' must be unique and
%   must match the channel name in the device (ai0, ai1, ai2, ...)!
% The variable 'device.inputChannel.name' must be unique!
device.inputRate=30E3;  %(in Hz)
device.inputChannel(1).id='ai16';
device.inputChannel(1).name='trialTrigger';
device.inputChannel(2).id='ai20';
device.inputChannel(2).name='everyFrame';

%% Analog Output channels
% The variable 'device.outputChannel.id' must be unique!
% The variable 'device.outputChannel.name' must be unique!
% The variable 'device.outputChannel.name' must match 'stimulus.name'!
device.outputRate=30E3; %(in Hz)
device.outputChannel(1).id='ao2';
device.outputChannel(1).name='trialTrigger';
device.outputChannel(2).id='ao3';
device.outputChannel(2).name='airpuff';
device.outputChannel(3).id='ao4';
device.outputChannel(3).name='audioStim';


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
run.tTotal=trial.backgroundTime+trial.N*trial.ISI+trial.postTrialRecordTime;
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
                tmpTone=stimulus(iStimulus).amplitude*sin(2*pi*stimulus(iStimulus).toneFrequency*tmpT)';
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

%% Build per-trial-type waveforms and assemble interleaved run sequence
% Each trial type only includes the stimuli listed in
% 'trialType(iType).activeStimuli' (defined above); all other output
% channels stay at 0V for that trial. The full run waveform (run.VOut)
% concatenates one ISI-length block per trial, in the order given by
% 'trial.order', so whisker-only, audio-only, and combined trials are
% interleaved within a single run.
run.VTrialType=cell(1,size(trialType,2));
for iType=1:size(trialType,2)
    tmpV=zeros(size(run.VTrial));
    for iStimulus=1:size(stimulus,2)
        if any(strcmp(trialType(iType).activeStimuli,stimulus(iStimulus).name))
            tmpInd=find(strcmp({device.outputChannel.name},stimulus(iStimulus).name));
            tmpV(:,tmpInd)=run.VTrial(:,tmpInd);
        end
    end
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
%% Prepare DAQ system
fprintf('\n\nPreparing DAQ system...')
daqreset; clearvars handler*
tmpInfo=daqlist(device.manufacturer);
%tmpInfo=tmpInfo(3,:)
tmpInd=find(strcmp({tmpInfo.DeviceInfo.Subsystems.SubsystemType},'AnalogInput'));
device.info.analogInput.channelNames=tmpInfo.DeviceInfo.Subsystems(tmpInd).ChannelNames;
tmpInd=find(strcmp({tmpInfo.DeviceInfo.Subsystems.SubsystemType},'AnalogOutput'));
device.info.analogOutput.channelNames=tmpInfo.DeviceInfo.Subsystems(tmpInd).ChannelNames;

%% Perform consistency checks
if size({device.inputChannel.id},2)~=size(unique({device.inputChannel.id}),2)
    error('Analog Input Channel ID (device.inputChannel.id) must be unique');
end
if size({device.inputChannel.name},2)~=size(unique({device.inputChannel.name}),2)
    error('Analog Input Channel Name (device.inputChannel.name) must be unique');
end
if size({device.outputChannel.id},2)~=size(unique({device.outputChannel.id}),2)
    error('Analog Output Channel ID (device.outputChannel.id) must be unique');
end
if size({device.outputChannel.name},2)~=size(unique({device.outputChannel.name}),2)
    error('Analog Output Channel Name (device.outputChannel.name) must be unique');
end

%% Check for correct Analog Input Channel and Output Channel assignment
for iChannel = 1:size(device.inputChannel,2)
    tmpInd=find(strcmp(device.info.analogInput.channelNames,device.inputChannel(iChannel).id));
    if isempty(tmpInd)
        error(['Analog Input Channel with ID ' device.inputChannel(iChannel).id ' is not available on ' device.name])
    end
end
for iChannel = 1:size(device.outputChannel,2)
    tmpInd=find(strcmp(device.info.analogOutput.channelNames,device.outputChannel(iChannel).id));
    if isempty(tmpInd)
        error(['Analog Output Channel with ID ' device.outputChannel(iChannel).id 'is not available on ' device.name])
    end
end
clear tmp*

%% Create Analog Input Handler
handlerDeviceInput=         daq(device.manufacturer);
handlerDeviceInput.Rate=    device.inputRate;
for iChannel=1:size(device.inputChannel,2)
    [~,device.inputChannelIndex(iChannel)]=addinput(handlerDeviceInput,device.name,device.inputChannel(iChannel).id,"Voltage");
    handlerDeviceInput.Channels(device.inputChannelIndex(iChannel)).TerminalConfig="SingleEnded";
    handlerDeviceInput.Channels(device.inputChannelIndex(iChannel)).Name=device.inputChannel(iChannel).name;
end

%% Create Analog Output Handler
handlerDeviceOutput=        daq(device.manufacturer);
handlerDeviceOutput.Rate =  device.outputRate;
for iChannel=1:size(device.outputChannel,2)
    [~,device.outputChannelIndex(iChannel)]=addoutput(handlerDeviceOutput,device.name,device.outputChannel(iChannel).id,"Voltage");
    handlerDeviceOutput.Channels(device.outputChannelIndex(iChannel)).Name=device.outputChannel(iChannel).name;
end

%% Load Analog Output to DAQ Card
preload(handlerDeviceOutput,run.VOut);
fprintf('done.')

%%
clc;
fprintf('\n *** %s ***',folder.fullfile);
fprintf('\nBackground Imaging Time Before Stimulus: %0.0f s', trial.backgroundTime)
fprintf('\nPost-trial recording time:               %0.0f s', trial.postTrialRecordTime)
fprintf('\nNumber of trials:                        %d', trial.N)
fprintf('\nSingle trial duration:                   %0.0f s', trial.ISI)
fprintf('\nTotal recording time:                    %0.0f s', run.tTotal)

%% Wait for user input
fprintf('\n\nPress any key to start run...'); pause

%% Perform run
fprintf('\nStarting analog input...')
start(handlerDeviceInput,"Duration",seconds(run.tTotal+10));
fprintf('\nPre-trial baseline');
pause(trial.backgroundTime)
fprintf('\nTrials...')
% run.VOut already contains the full interleaved N-trial sequence
% (see 'Build per-trial-type waveforms...' above), so it is played once,
% not repeated.
start(handlerDeviceOutput)
pause(trial.N*trial.ISI)
stop(handlerDeviceOutput)
fprintf('\nPost-trial recording time...')
pause(trial.postTrialRecordTime)
pause(10);
fprintf('\nAcquistion finished.')
%% Load analog input and save into mat file
fprintf('\nReading analog input and save to file...')
analogInput = read(handlerDeviceInput,"all");
save(folder.fullfile,'analogInput','trial','trialType','stimulus','folder','device');
fprintf('done.')
fprintf('\nFinished.\n')
daqreset; clearvars handler*
