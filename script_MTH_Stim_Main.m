%% Prepare workspace
clearvars; clc; daqreset;

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
% | %  Contains stimulus sequences     %
% | %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% |
% | postTrialRecordTime (in s)
% |
%\|/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trial.N = 5 ; %EPI n=20 or 30 for stim runs; n=10@5 or 20Hz for RS
    %ephys: 30, 10
trial.ISI=5;% (in s) %20 long 5Hz,30sec
    %ephys: 10
trial.backgroundTime=5;%20 long 5Hz,30sec
    %ephys: 120, 600
trial.postTrialRecordTime=0;% (in s) Extra recording 
%time after last trial %20 long 5Hz,30sec
% Derived from previous parameters 
    %ephys: 30
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
% stimulus(1).name='trialTrigger';
% stimulus(1).type='rect';                % options: rect
% stimulus(1).delay=0;                    % delay (in s) from trial start to first pulse
% stimulus(1).pulseWidth=10e-3;            % width (in s) of individual pulses
% stimulus(1).frequency=1;                % frequency (in Hz) of pulse trail---
% stimulus(1).duration=1;                 % duration of pulse train
% stimulus(1).amplitude=5;                % amplitude (in V) of individual pulses

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

%% Analog Output channels
% The variable 'device.outputChannel.id' must be unique!
% The variable 'device.outputChannel.name' must be unique!
% The variable 'device.outputChannel.name' must match 'stimulus.name'!
device.outputRate=30E3; %(in Hz)
% device.outputChannel(1).id='ao0';
% device.outputChannel(1).name='trialTrigger';
device.outputChannel(1).id='ao0';
device.outputChannel(1).name='audio';
device.outputChannel(2).id='ao1';
device.outputChannel(2).name='airpuff';


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
run.VOut=zeros(device.outputRate*trial.ISI,size(device.outputChannel,2));
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
                    run.VOut(tmpPulseStartInd:tmpPulseEndInd,tmpInd)=tmpPulseAmplitude;
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
                %run.VTrial(tmpStimStart:tmpStimEnd,tmpInd)=tmpTone;
                run.VOut(tmpStimStart:tmpStimEnd,tmpInd)=tmpTone;
                if tmpStimEnd>size(run.tTrial,2)
                    error('Stimulus is longer than trial ISI.')
                end
            otherwise
                error('Unknown stimulus type.')
        end
    else
        error([stimulus(iStimulus).name ' not found in device.outputChannel.name!'])
    end
run.VOut(end-100:end,tmpInd)=0; % MTH 09/20/21 added to solve problem with airpuff blowing like the big bad wulf 
end
clearvars tmp* i*
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
tmpInfo=tmpInfo(1,:)
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
fprintf('\nBackground Imaging Time Before Airpuff:  %0.0f s', trial.backgroundTime)
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
start(handlerDeviceOutput,"RepeatOutput")
pause(trial.N*trial.ISI)
stop(handlerDeviceOutput)
fprintf('\nPost-trial recording time...')
pause(trial.postTrialRecordTime)
pause(10);
fprintf('\nAcquistion finished.')
%% Load analog input and save into mat file
fprintf('\nReading analog input and save to file...')
analogInput = read(handlerDeviceInput,"all");
save(folder.fullfile,'analogInput','trial','stimulus','folder','device');
fprintf('done.')
fprintf('\nFinished.\n')
daqreset; clearvars handler*