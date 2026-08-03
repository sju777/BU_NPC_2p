% run the pavlovian task 
% Mai-Anh Vu
% 11/9/2021
% edited 2/21/2022 for 2 LEDs
function SalientStimuli_Run

global session
% % if we're delivering unpredicted reward
% if session.temp.currentUR>0 && session.exp.trials.unpredRew(session.temp.currentTrial)>0
%     if toc(session.temp.rewTimer) >= floor(session.temp.ITI/2)
%         disp('* unpred rew *')
%         RewardDeliver(session.exp.trials.unpredRew(session.temp.currentTrial));
%         session.temp.currentUR = -1;
%     end
% end
% if the right amount of time has passed for another trial
if session.temp.currentTrial<=session.exp.n_trials && toc(session.temp.rewTimer)>=session.temp.ITI
    if session.temp.stimulusOn == 0 % if it's currently off and we need to turn it on
        session.temp.stimTimer = tic;
        salientStimuli_stimulusOn;
    end
    if toc(session.temp.stimTimer)>= session.exp.stim_dur
        % turn off stim if it's on
        if session.temp.stimulusOn == 1;
            salientStimuli_stimulusOff;        
        end
        % increment current Trial
        session.temp.currentTrial = session.temp.currentTrial + 1;
        % restart ITI timer
        session.temp.rewTimer = tic;        
        % update task variables
        if session.temp.currentTrial <= session.exp.n_trials
            %session.temp.currentUR = session.exp.trials.unpredRew(session.temp.currentTrial);
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
session.temp.stimLabel = {'LED','tone'};
disp(' *** ')
disp(['trial #' num2str(session.temp.currentTrial) ' in ' num2str(session.temp.ITI) 's:'])
str1 = session.temp.stimLabel{session.temp.currentStim+1};
if session.temp.currentStim==1
    str2 = [' ' num2str(session.temp.currentFreq) 'kHz'];
else
    str2 = [' ' num2str(abs(session.temp.currentFreq))];
end
str3 = [' level ' num2str(session.temp.currentLevel)];
disp([str1 str2 str3])
 
% stimulus on
function salientStimuli_stimulusOn
global session
% turn on stimulus if it isn't on yet
stimOn = session.nidaq.outputZeros;
if session.temp.currentStim == 1
    if session.temp.stimulusOn==0 
        % generate and play sound
        generateCurrentSound(session.temp.currentFreq,session.temp.currentLevel)
        play(session.temp.currentSound,session.temp.fs);
    end
    stimOn(session.nidaqCh.outIdx_stimulus_sound-1)=1;
else
    if session.temp.stimulusOn == 0
        if session.temp.currentFreq == -1
            % generate LED data  
            session.nidaq.s4.queueOutputData([ones(1000*session.exp.stim_dur,1)*session.temp.currentLevel; 0]);
            session.nidaq.s4.startBackground();
            stimOn(session.nidaqCh.outIdx_stimulus_led-1)=1;
        elseif session.temp.currentFreq == -2
            % generate LED data  
            session.nidaq.s5.queueOutputData([ones(1000*session.exp.stim_dur,1)*session.temp.currentLevel; 0]);
            session.nidaq.s5.startBackground();
            stimOn(session.nidaqCh.outIdx_stimulus_led2-1)=1;
        end            
    end
end
% send signal
outputSingleScan(session.nidaq.s2,stimOn);
session.temp.stimulusOn = 1;


% generate sound cue
function generateCurrentSound(thisFreq,thisVol)
global session
nSeconds = 2*session.exp.stim_dur;
fs = 44100;
session.temp.currentSound = audioplayer(thisVol * sin(linspace(0, nSeconds*1000*thisFreq*2*pi, round(nSeconds*fs))),fs);
session.temp.fs = fs;
    

% stimulus off
function salientStimuli_stimulusOff
global session

% turn off sound
%clear sound
if session.temp.currentStim == 1
    stop(session.temp.currentSound);
end
session.temp.stimulusOn = 0;

% turn off corollary discharge
stimOff = session.nidaq.outputZeros;
outputSingleScan(session.nidaq.s2,stimOff);


