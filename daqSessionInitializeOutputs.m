% daqSessionInitializeOutputs.m gathers all the outputs set, and
% initializes the output signals and indices appropriately
% These outputs are all on daq session session.nidaq.s2
%
% updated by Mai-Anh Vu 12/10/2018
% updated by Mai-Anh Vu 9/21/2020 to include 5V square switch

global session % our global variable to store everything

% turn off all digital channels
session.nidaq.outputZeros = zeros(size(session.nidaq.s2.Channels));

% the output reward pulse
session.nidaq.rewardPulse = session.nidaq.outputZeros;
session.nidaq.rewardPulse(session.nidaqCh.outIdx_rew-1) = 1; 


% the output TTL pulse
session.nidaq.TTLpulse = session.nidaq.outputZeros;
session.nidaq.TTLpulse(session.nidaqCh.outIdx_ttl-1) = 1;  

% square wave triggering
if isfield(session.exp,'squareSwitch') && session.exp.squareSwitch==1
    session.nidaq.TTLsquare = session.nidaq.outputZeros;
    session.nidaq.TTLsquare(session.nidaqCh.outIdx_squareSwitch-1) = 1;
end

% the output signal for the delay conditioning task
if isfield(session,'exp') && isfield(session.exp,'delayCond') && session.exp.delayCond==1
    if session.rew.delayCondLED == 1
        session.nidaq.delayCondStimLED = session.nidaq.outputZeros;
        session.nidaq.delayCondStimLED(session.nidaqCh.outIdx_stimulus-1)=1;
    end
    if session.rew.delayCondSound == 1        
        %session.temp.soundCue.fs = 2.25*1000*session.rew.delayCondSound_kHz;
        session.temp.soundCue.fs = 44100; % this is a pretty good fs for sounds
        session.temp.soundCue.cue = sin(linspace(0, 1.25*session.rew.stimDelay*1000*session.rew.delayCondSound_kHz*2*pi, round(session.rew.stimDelay*session.temp.soundCue.fs)));
        session.temp.soundOn = 0; % a temp var to keep track if sound is on or not
        if session.temp.soundTTL == 1
            disp('Running delay conditioning with sound')
            disp('but no sound recording Nidaq channel.')
            disp('Each stimulus onset will be marked by')
            disp('a triple TTL pulse, which you can find')
            disp('in the TTLout field of your saved data.')
        end
        session.nidaq.delayCondStimSound = session.nidaq.outputZeros;
        session.nidaq.delayCondStimSound(session.nidaqCh.outIdx_stimulus_sound-1)=1;
    elseif session.rew.delayCondLED==0
        disp('you are running delay cond without LED')
        disp('or sound. defaulting to LED.')
        session.rew.delayCondLED=1;
    end
end
        
