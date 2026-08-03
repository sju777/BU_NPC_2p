% run the audio / airpuff / paired task
% Modeled after SalientStimuli_Run.m (Mai-Anh Vu, 11/9/2021).
%
% session.temp.currentStim modality codes:
%   0 = audio only
%   1 = airpuff only
%   2 = paired (audio + airpuff, simultaneous onset)
%
% The "on" value written to each stimulus channel (session.exp.stimAudio-
% OnValue / session.exp.stimAirpuffOnValue, set in PairedStimuli_Initialize.m)
% is 1 for a digital channel or the configured amplitude (volts) for an
% analog channel -- whichever the DAQ Channels table currently assigns
% to that stimulus.
%
% Audio: if the DAQ Channels table assigns Audio to an ANALOG output,
% generateCurrentSound (below) builds an actual sine wave -- at the
% current trial's frequency (kHz) and session.exp.audio_dur seconds --
% and sends it to the DAQ via a dedicated background session
% (session.nidaq.s4, see PairedStimuli_Initialize.m). If Audio is
% assigned a DIGITAL output instead, the tone plays through this
% computer's speakers as before, with only a TTL marker sent to the DAQ.
% session.exp.audioIsAnalogOut records which mode is active.
%
% The airpuff is a PULSE TRAIN, not a single pulse: session.exp.
% airpuff_pulse_len (on-time per pulse), session.exp.airpuff_ipi (gap
% between pulses), and session.exp.airpuff_n_pulses (# of pulses) are set
% from the Airpuff panel in PairedStimuli.m; session.exp.airpuff_dur is
% the resulting total train time (n_pulses*pulse_len +
% (n_pulses-1)*ipi). The train runs independently of the overall
% session.exp.stim_dur trial window used for the tone / polling timeout,
% so on paired trials the tone can keep playing after the airpuff train
% finishes (the train is validated to fit within stim_dur at Setup OK).
% Like the rest of this task's timing, the train is software-polled (via
% tic/toc on each DataAvailable callback), not hardware-timed -- fine for
% the pulse widths/intervals this task uses, but not sample-accurate.
function PairedStimuli_Run

global session
% if the right amount of time has passed for another trial
if session.temp.currentTrial<=session.exp.n_trials && toc(session.temp.rewTimer)>=session.temp.ITI
    if session.temp.stimulusOn == 0 % if it's currently off and we need to turn it on
        session.temp.stimTimer = tic;
        pairedStimuli_stimulusOn;
    end
    % advance the airpuff pulse train independently of the overall trial/
    % stim window, even if the tone is still playing on a paired trial
    if session.temp.airpuffPulseIdx > 0
        pairedStimuli_airpuffTrainUpdate;
    end
    if toc(session.temp.stimTimer)>= session.exp.stim_dur
        % turn off stim if it's on
        if session.temp.stimulusOn == 1
            pairedStimuli_stimulusOff;
        end
        % increment current Trial
        session.temp.currentTrial = session.temp.currentTrial + 1;
        % restart ITI timer
        session.temp.rewTimer = tic;
        % update task variables
        if session.temp.currentTrial <= session.exp.n_trials
            trialUpdate
        else
            disp(['***** TASK FINISHED ' datestr(clock) ' *****'])
        end
    end
end


function trialUpdate
global session

% update some variables
session.temp.ITI = session.exp.trials.iti(session.temp.currentTrial);
session.temp.currentStim = session.exp.trials.modality(session.temp.currentTrial);
session.temp.currentFreq = session.exp.trials.frequency(session.temp.currentTrial);
session.temp.currentLevel = session.exp.trials.level(session.temp.currentTrial);

% display trial information
session.temp.stimLabel = {'audio','airpuff','paired'};
disp(' *** ')
disp(['trial #' num2str(session.temp.currentTrial) ' in ' num2str(session.temp.ITI) 's:'])
str1 = session.temp.stimLabel{session.temp.currentStim+1};
if session.temp.currentStim==1 % airpuff-only: no tone to report
    str2 = ' ';
    str3 = sprintf(' %dx%.3gs pulses, %.3gs IPI, %.3gs total', ...
        session.exp.airpuff_n_pulses, session.exp.airpuff_pulse_len, session.exp.airpuff_ipi, session.exp.airpuff_dur);
else
    str2 = [' ' num2str(session.temp.currentFreq) 'kHz'];
    str3 = [' level ' num2str(session.temp.currentLevel)];
end
disp([str1 str2 str3])

% stimulus on
function pairedStimuli_stimulusOn
global session
% turn on stimulus if it isn't on yet
stimOn = session.nidaq.outputZeros;
switch session.temp.currentStim
    case 0 % audio only
        if session.temp.stimulusOn==0
            generateCurrentSound(session.temp.currentFreq,session.temp.currentLevel)
        end
        if ~session.exp.audioIsAnalogOut
            stimOn(session.nidaqCh.outIdx_stimulus_sound-1)=session.exp.stimAudioOnValue;
        end
    case 1 % airpuff only
        if session.temp.stimulusOn==0
            startAirpuffTrain; % pulse 1 of the train starts now
        end
        stimOn(session.nidaqCh.outIdx_stimulus_tactile-1)=session.exp.stimAirpuffOnValue;
    case 2 % paired: audio + airpuff, simultaneous onset
        if session.temp.stimulusOn==0
            generateCurrentSound(session.temp.currentFreq,session.temp.currentLevel)
            startAirpuffTrain; % pulse 1 of the train starts now
        end
        if ~session.exp.audioIsAnalogOut
            stimOn(session.nidaqCh.outIdx_stimulus_sound-1)=session.exp.stimAudioOnValue;
        end
        stimOn(session.nidaqCh.outIdx_stimulus_tactile-1)=session.exp.stimAirpuffOnValue;
end
% send signal
outputSingleScan(session.nidaq.s2,stimOn);
session.temp.currentOutputState = stimOn;
session.temp.stimulusOn = 1;


% generate the tone: session.exp.audio_dur seconds of a
% session.temp.currentFreq (kHz) sine wave at peak amplitude thisVol.
% If Audio is assigned an analog DAQ channel, this queues the actual
% waveform to session.nidaq.s4 and starts it playing on the DAQ's analog
% output (a real sine wave sent to the DAQ, per the Audio panel's
% Frequency/Duration parameters). Otherwise it plays through this
% computer's speakers exactly as before, with only a TTL marker sent to
% the DAQ (session.exp.stimAudioOnValue, written by the caller).
function generateCurrentSound(thisFreq,thisVol)
global session
if session.exp.audioIsAnalogOut
    fs = session.nidaq.s4.Rate;
    nSamples = round(session.exp.audio_dur*fs);
    t = (0:nSamples-1)'/fs;
    waveform = thisVol * sin(2*pi*(thisFreq*1000)*t); % thisFreq is in kHz
    stop(session.nidaq.s4); % clear anything still queued from a previous trial
    session.nidaq.s4.queueOutputData(waveform);
    session.nidaq.s4.startBackground(); % DAQ plays this exact-length buffer and then stops on its own
else
    nSeconds = 2*session.exp.audio_dur; % extra margin; pairedStimuli_stimulusOff cuts it off explicitly anyway
    fs = 44100;
    session.temp.currentSound = audioplayer(thisVol * sin(linspace(0, nSeconds*1000*thisFreq*2*pi, round(nSeconds*fs))),fs);
    session.temp.fs = fs;
    play(session.temp.currentSound,session.temp.fs);
end


% start the airpuff pulse train: pulse #1 begins in the "on" phase (the
% caller is responsible for actually setting the output bit high)
function startAirpuffTrain
global session
session.temp.airpuffPulseIdx = 1;
session.temp.airpuffPhase = 'on';
session.temp.airpuffPhaseTimer = tic;

% advance the airpuff pulse train by one tick: flips between the "on"
% (airpuff_pulse_len) and "off"/inter-pulse (airpuff_ipi) phases, and
% starts the next pulse once the gap elapses. airpuffPulseIdx is reset to
% 0 once all session.exp.airpuff_n_pulses pulses have fired.
function pairedStimuli_airpuffTrainUpdate
global session
if strcmp(session.temp.airpuffPhase,'on')
    if toc(session.temp.airpuffPhaseTimer) >= session.exp.airpuff_pulse_len
        setAirpuffBit(0); % this pulse's on-time is over
        if session.temp.airpuffPulseIdx >= session.exp.airpuff_n_pulses
            session.temp.airpuffPulseIdx = 0; % train finished
        elseif session.exp.airpuff_ipi <= 0
            % no gap requested -- start the next pulse immediately
            session.temp.airpuffPulseIdx = session.temp.airpuffPulseIdx + 1;
            session.temp.airpuffPhaseTimer = tic;
            setAirpuffBit(session.exp.stimAirpuffOnValue);
        else
            session.temp.airpuffPhase = 'off';
            session.temp.airpuffPhaseTimer = tic;
        end
    end
else % 'off' phase: waiting out the inter-pulse interval
    if toc(session.temp.airpuffPhaseTimer) >= session.exp.airpuff_ipi
        session.temp.airpuffPulseIdx = session.temp.airpuffPulseIdx + 1;
        session.temp.airpuffPhase = 'on';
        session.temp.airpuffPhaseTimer = tic;
        setAirpuffBit(session.exp.stimAirpuffOnValue);
    end
end

% set just the airpuff output bit to the given value, leaving any other
% active output (e.g. the tone's corollary-discharge bit on a paired
% trial) untouched
function setAirpuffBit(value)
global session
stimNow = session.temp.currentOutputState;
stimNow(session.nidaqCh.outIdx_stimulus_tactile-1) = value;
outputSingleScan(session.nidaq.s2,stimNow);
session.temp.currentOutputState = stimNow;


% stimulus off
function pairedStimuli_stimulusOff
global session

% turn off sound
if session.temp.currentStim == 0 || session.temp.currentStim == 2
    if session.exp.audioIsAnalogOut
        stop(session.nidaq.s4);
        session.nidaq.s4.queueOutputData(zeros(500,1)); % return to 0V between trials
        session.nidaq.s4.startBackground();
    else
        stop(session.temp.currentSound);
    end
end
session.temp.stimulusOn = 0;
session.temp.airpuffPulseIdx = 0; % force-stop the pulse train (should already be finished)

% turn off corollary discharge
stimOff = session.nidaq.outputZeros;
outputSingleScan(session.nidaq.s2,stimOff);
session.temp.currentOutputState = stimOff;
