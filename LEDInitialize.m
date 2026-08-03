% initialize outputs for LED triggers
% Mai-Anh Vu 7/14/2020

global session % our global variable to store everything

% set to something <1 if you want a complete off before the next on
% otherwise, when dutyCycleFrac==1, one LED turns off simultaneously with
% the next LED turning on
dutyCycleFrac = 1; 

% create another session for outputs LED triggers
disp('initializing LED square waves')
session.nidaq.s3 = daq.createSession('ni');
session.nidaq.s3.Rate = 2000; % samples/second (here we set to 2kHz)
session.nidaq.s3.IsContinuous=1;
if sum(session.exp.LEDon)==1
    disp('You only have 1 LED selected.')
    disp('The duty cycle will be set to .9999.')
    disp('Other option: remove the BNC trigger,')
    disp('and just turn it on manually.')
end

if sum(session.exp.LEDon)==3
    disp('You have selected all 3 LEDs.')
    disp('The green camera will be triggered')
    disp('on every LED. Offline, ignore the')
    disp('frames coinciding with the red camera');
end

% set output channels
% 470nm: J2 (PFI12)
if session.exp.LEDon(1) == 1
    [led470,session.nidaqCh.chIdx_LED470] = addCounterOutputChannel(session.nidaq.s3,session.temp.dev,'ctr0','PulseGeneration');
    led470.Frequency = session.exp.LEDrecFreq/sum(session.exp.LEDon);    
    if sum(session.exp.LEDon)==1
        led470.DutyCycle = 0.9999;
    else
        led470.DutyCycle = dutyCycleFrac/sum(session.exp.LEDon);        
    end
    led470.InitialDelay = 0;
end
% 570nm: J40 (PFI13)
if session.exp.LEDon(2) == 1
    [led570,session.nidaqCh.chIdx_LED570] = addCounterOutputChannel(session.nidaq.s3,session.temp.dev,'ctr1','PulseGeneration');    
    led570.Frequency = session.exp.LEDrecFreq/sum(session.exp.LEDon);
    if sum(session.exp.LEDon)==1
        led570.DutyCycle = .9999;
    else
        led570.DutyCycle = dutyCycleFrac/sum(session.exp.LEDon);        
    end
    led570.InitialDelay = session.exp.LEDon(1)/led570.Frequency/sum(session.exp.LEDon);
end
% 405nm: J1 (PFI14)
if session.exp.LEDon(3) == 1
    [led405,session.nidaqCh.chIdx_LED405] = addCounterOutputChannel(session.nidaq.s3,session.temp.dev,'ctr2','PulseGeneration');    
    led405.Frequency = session.exp.LEDrecFreq/sum(session.exp.LEDon);    
    if sum(session.exp.LEDon)==1
        led405.DutyCycle = .9999;
    else
        led405.DutyCycle = dutyCycleFrac/sum(session.exp.LEDon);        
    end
    led405.InitialDelay = sum(session.exp.LEDon(1:2))/led405.Frequency/sum(session.exp.LEDon);
end

% green camera trigger
if session.exp.LEDon(1) == 1 || session.exp.LEDon(3) == 1
    [ledgreen2,session.nidaqCh.chIdx_LEDgreen2] = addCounterOutputChannel(session.nidaq.s3,session.temp.dev,'ctr3','PulseGeneration');    
    ledgreen2.DutyCycle = .25; % edge-triggered, so duty cycle doesn't matter
end
% if BOTH 470 and 405 are selected, trigger on every LED trigger
% note that if all 3 LEDs are on, you'll have frames acquired during red
% LED too
if session.exp.LEDon(1) == 1 && session.exp.LEDon(3) == 1
    ledgreen2.Frequency = session.exp.LEDrecFreq; % trigger on every acq
    ledgreen2.InitialDelay = 0;    
% otherwise, if just 407, duplicate that
elseif session.exp.LEDon(1) == 1 && session.exp.LEDon(3) == 0
    ledgreen2.Frequency = led470.Frequency;
    ledgreen2.InitialDelay = led470.InitialDelay;
% otherwise, if just 405, duplicate that
elseif session.exp.LEDon(1) == 0 && session.exp.LEDon(3) == 1
    ledgreen2.Frequency = led405.Frequency;
    ledgreen2.InitialDelay = led405.InitialDelay;
end

% start this in the background
session.nidaq.s3.startBackground;
