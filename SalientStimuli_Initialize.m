% initialize inputs and outputs for auditory pavlovian task
% Mai-Anh Vu
% 11/9/2021
% edited 2/21/2022 for 2 LEDs

function SalientStimuli_Initialize
global session % our global variable to store everything

% % add digital input channel (breakout #2 J11: P0.16) to record reward delivery
% [~,session.nidaqCh.chIdx_rew] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line16','InputOnly');
% add digital input channel (breakout #1 J71: P0.1) to record reward delivery
[~,session.nidaqCh.chIdx_rew] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line1','InputOnly');
session.nidaqCh.chIdx_rew=session.nidaqCh.chIdx_rew+1;

% add digital input channel (J47: P0.3) to record licking
[~,session.nidaqCh.chIdx_lick] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line3','InputOnly');
session.nidaqCh.chIdx_lick=session.nidaqCh.chIdx_lick+1;

% % add digital output channel (breakout #2 J10: P0.17) to trigger reward delivery
% [ch_rew,session.nidaqCh.outIdx_rew] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line17','OutputOnly');
% add digital output channel (breakout #1 J42: P1.3) to trigger reward delivery
[~,session.nidaqCh.outIdx_rew] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port1/Line3','OutputOnly');
session.nidaqCh.outIdx_rew=session.nidaqCh.outIdx_rew+1;

% timers & listeners
%session.temp.rewTimer = tic; % start a reward timer    
%session.temp.currentUR = -1;
session.temp.currentTrial = 1;
session.nidaq.lh3 = session.nidaq.s.addlistener('DataAvailable', @(src,event) SalientStimuli_Run);


% add digital output channel (J16 (second board): P0.14) to reflect cond. sound stim
[~,session.nidaqCh.outIdx_stimulus_sound] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line14','OutputOnly');
session.nidaqCh.outIdx_stimulus_sound=session.nidaqCh.outIdx_stimulus_sound+1;
% add a digital input channel (J49 (second board): P0.10) to record sound stimulus
[~,session.nidaqCh.chIdx_stimulus_sound] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line10','InputOnly');
session.nidaqCh.chIdx_stimulus_sound = session.nidaqCh.chIdx_stimulus_sound+1;
session.exp.stimulus_sound = 1;

% LED 1
% add digital output channel (J51: P0.5) to trigger LED stim
[~,session.nidaqCh.outIdx_stimulus_led] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line5','OutputOnly');
session.nidaqCh.outIdx_stimulus_led=session.nidaqCh.outIdx_stimulus_led+1;
% add a digital input channel (J52: P0.0) to record LED stimulus
[~,session.nidaqCh.chIdx_stimulus_led] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line0','InputOnly');
session.nidaqCh.chIdx_stimulus_led = session.nidaqCh.chIdx_stimulus_led+1;
session.exp.stimulus_led = 1;
% add digital output channel (ao3) to trigger LED ANALOG stim
session.nidaq.s4 = daq.createSession('ni');
session.nidaq.s4.Rate = 1000; % samples/second 
%session.nidaq.s4.IsContinuous = 1; % continuous
[~,session.nidaqCh.outIdx_stimulus_led_analog] = addAnalogOutputChannel(session.nidaq.s4, session.temp.dev, 'ao3', 'Voltage');
session.nidaqCh.outIdx_stimulus_led_analog = session.nidaqCh.outIdx_stimulus_led_analog+1;
session.nidaq.s4.queueOutputData(zeros(500,1)); % send 0s in case
session.nidaq.s4.startBackground();
% add a digital input channel (ai22) to record LED ANALOG stimulus
[~,session.nidaqCh.chIdx_stimulus_led_analog] = addAnalogInputChannel(session.nidaq.s,session.temp.dev,'ai22','Voltage');
session.nidaqCh.chIdx_stimulus_led_analog = session.nidaqCh.chIdx_stimulus_led_analog+1;
session.exp.stimulus_led_analog = 1;

% LED 2
% add digital output channel (J42 2nd breakout: P0.19) to trigger LED stim
[~,session.nidaqCh.outIdx_stimulus_led2] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line19','OutputOnly');
session.nidaqCh.outIdx_stimulus_led2=session.nidaqCh.outIdx_stimulus_led2+1;
% add a digital input channel (J43 2nd breakout: P0.18) to record LED stimulus
[~,session.nidaqCh.chIdx_stimulus_led2] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line18','InputOnly');
session.nidaqCh.chIdx_stimulus_led2 = session.nidaqCh.chIdx_stimulus_led2+1;
session.exp.stimulus_led2 = 1;
% add digital output channel (ao2) to trigger LED ANALOG stim 
% (borrow stim driver pin)
session.nidaq.s5 = daq.createSession('ni');
session.nidaq.s5.Rate = 1000; % samples/second 
%session.nidaq.s5.IsContinuous = 1; % continuous
[~,session.nidaqCh.outIdx_stimulus_led2_analog] = addAnalogOutputChannel(session.nidaq.s5, session.temp.dev, 'ao2', 'Voltage');
session.nidaqCh.outIdx_stimulus_led2_analog = session.nidaqCh.outIdx_stimulus_led2_analog+1;
session.nidaq.s5.queueOutputData(zeros(500,1)); % send 0s in case
session.nidaq.s5.startBackground();
% add a digital input channel (ai23) to record LED 2 ANALOG stimulus
[~,session.nidaqCh.chIdx_stimulus_led2_analog] = addAnalogInputChannel(session.nidaq.s,session.temp.dev,'ai23','Voltage');
session.nidaqCh.chIdx_stimulus_led2_analog = session.nidaqCh.chIdx_stimulus_led2_analog+1;
session.exp.stimulus_led2_analog = 1;


% activate channels & setup reward magnitudes
session.exp.rew=1;
session.exp.lick=1;

% keep track of reward volume delivered (uL)
session.rew.totalVolDelivered = 0;
session.rew.rewCounts = [0 0 0];
session.rew.rewSize = [];
if session.exp.delayCond==1
    session.rew.rewTrials = 0;
    session.rew.omitTrials = 0;
end

session.temp.stimulusOn = 0; % stimulus is currently off



