% daqSessionUpdateDataBuffer.m initializes the listener to update the data 
% buffer based on the length of the plot window (as set by the user upon 
% initialization) and plot whatever there is to plot, based on what's being
% gathered
%
% updated by Mai-Anh Vu 12/10/2018
% updated by Mai-Anh Vu 06/18/2019 to include 2d ball
% updated by Mai-Anh 11/17/2021 to include pavlovian2cue task (but also
% many updates have been made before now

function daqSessionInitializeDataBuffer(varargin)
global session % our global variable to store everything
% define our listener function

str1 = 'session.nidaq.lh2 = session.nidaq.s.addlistener(''DataAvailable'', @(src,event) (cellfun(@(x)feval(x,src,event),{@(src,event)daqSessionUpdateDataBuffer(event)';
str_rotEnc = '';
str_pos = '';
str_ball = '';
str_ttlOut = '';
str_ttlOut2 = '';
str_ttlIn = '';
str_ttlIn2 = '';
str_ttlSquare = '';
str_ttlSquare2 = '';
str_stimDriver = '';
str_stimDriver2 = '';
str_rew = '';
str_rew2 = '';
str_delayCond = '';
str_delayCond2 = '';
str_delayCondSound = '';
str_delayCondSound2 = '';
str_touch = '';
str_touch2 = '';
% rotary encoder
if isfield(session.nidaqCh,'rotEnc') % if we've initialized a channel for this
    str_rotEnc = ',@(src,event)daqSessionPlotEvent_Velocity(session.handles.axes1)';
    str_pos = ',@(src,event)daqSessionPlotEvent_Position(session.handles.axes2)';
end
if isfield(session.nidaqCh,'chIdx_ball') % if we've initialized a channel for this
    str_ball = ',@(src,event)daqSessionPlotEvent_BallVelocity(session.handles.axes1)';
end
% TTL pulses sent out
str_ttlOut = ',@(src,event)daqSessionPlotEvent_TTLout(session.handles.axes1)';
str_ttlOut2 = ',@(src,event)daqSessionPlotEvent_TTLout(session.handles.axes2)';

% received TTL pulses
str_ttlIn = ',@(src,event)daqSessionPlotEvent_TTLin(session.handles.axes1)'; 
str_ttlIn2 = ',@(src,event)daqSessionPlotEvent_TTLin(session.handles.axes2)'; 

% 5V square trigger
if isfield(session.nidaqCh,'chIdx_squareSwitch') || isfield(session.nidaqCh,'chIdx_stimulation') % if we've initialized a channel for this
    str_ttlSquare = ',@(src,event)daqSessionPlotEvent_TTLsquare(session.handles.axes1)'; 
    str_ttlSquare2 = ',@(src,event)daqSessionPlotEvent_TTLsquare(session.handles.axes2)'; 
end
% stim driver
if isfield(session.nidaqCh,'chIdx_stimDriver') % if we've initialized a channel for this
    str_stimDriver = ',@(src,event)daqSessionPlotEvent_stimDriver(session.handles.axes1)'; 
    str_stimDriver2 = ',@(src,event)daqSessionPlotEvent_stimDriver(session.handles.axes2)'; 
end
% triggered reward & tasks
str_rew = ',@(src,event)daqSessionPlotEvent_Reward(session.handles.axes1)';
str_rew2 = ',@(src,event)daqSessionPlotEvent_Reward(session.handles.axes2)';
if isfield(session.exp,'delayCond') && session.exp.delayCond == 1
    str_delayCond = ',@(src,event)daqSessionPlotEvent_delayCondStim(session.handles.axes1)';
    str_delayCond2 = ',@(src,event)daqSessionPlotEvent_delayCondStim(session.handles.axes2)';   
elseif isfield(session.exp,'pav_2cue') && session.exp.pav_2cue == 1
    str_delayCond = ',@(src,event)daqSessionPlotEvent_Pavlovian2Cue(session.handles.axes1)';
    str_delayCond2 = ',@(src,event)daqSessionPlotEvent_Pavlovian2Cue(session.handles.axes2)';
elseif isfield(session.exp,'salient_stim') && session.exp.salient_stim == 1
    str_delayCond = ',@(src,event)daqSessionPlotEvent_SalientStimuli(session.handles.axes1)';
    str_delayCond2 = ',@(src,event)daqSessionPlotEvent_SalientStimuli(session.handles.axes2)';
elseif isfield(session.exp,'pred_2cue') && session.exp.pred_2cue == 1
    str_delayCond = ',@(src,event)daqSessionPlotEvent_Pred2Cue(session.handles.axes1)';
    str_delayCond2 = ',@(src,event)daqSessionPlotEvent_Pred2Cue(session.handles.axes2)';
end

% touch_sensors : if any of the touch sensors have been initialized
if isfield(session.nidaqCh,'chIdx_touchBar') || ...
        isfield(session.nidaqCh,'chIdx_touchL') || ...
        isfield(session.nidaqCh,'chIdx_touchR')    
    str_touch = ',@(src,event)daqSessionPlotEvent_touchSensors(session.handles.axes1)'; 
    str_touch2 = ',@(src,event)daqSessionPlotEvent_touchSensors(session.handles.axes2)'; 
end

str2 = '})));';

% plot reward and TTLs on second axes?
if isempty(varargin) || varargin{1} == 2
    str_rew = str_rew2;
    str_delayCond = str_delayCond2;
    str_ttlOut = str_ttlOut2;
    str_ttlIn = str_ttlIn2;
    str_ttlSquare = str_ttlSquare2;
    str_stimDriver = str_stimDriver2;
    str_touch = str_touch2;
end
    
cmdStr = [str1 str_rotEnc str_ball str_ttlOut str_ttlIn str_ttlSquare str_stimDriver str_rew str_delayCond str_touch str2];

% evaluate the command string: run the appropriate listener function
eval(cmdStr);
    
        
