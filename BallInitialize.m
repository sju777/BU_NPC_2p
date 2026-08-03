
% BallInitialize initializes the data acquisition session to read input
% from the 2d ball treadmill
% this version sends the absolute value of the velocity, and then a
% separate signal for the sign
%
% Mapping
% Mouse1
% GND: 
% X:
% Y:
global session % our global variable to store everything

% the number of optical mice: 2
% mouse 1 captures yaw and pitch
% mouse 2 captures yaw and roll
numOpticalMice = 2;
%numOpticalMice = 1;


% velocity magnitude pins: mouse1 dx, mouse1 dy; mouse2 dx, mouse2 dy 
vpins = {'ai2','ai3';'ai4','ai5'};
% velocity sign pins: mouse1 dx, mouse1 dy; mouse2 dx, mouse2 dy 
spins = {'ai0','ai1';'ai6','ai7'};
session.nidaqCh.chIdx_ball = zeros(numOpticalMice,4);

    

% add our 2 analog inputs (x-velocity and y-velocity) for each mouse
for n = 1:numOpticalMice
    for ch = 1:2
        % add the analog input that carries the magnitude
        [~,session.nidaqCh.chIdx_ball(n,ch)] = addAnalogInputChannel(session.nidaq.s, session.temp.dev, vpins{n,ch}, 'Voltage');    
        session.nidaqCh.chIdx_ball(n,ch)=session.nidaqCh.chIdx_ball(n,ch)+1;
        % add the digital input that carries the sign
        [~,session.nidaqCh.chIdx_ball(n,ch+2)] = addAnalogInputChannel(session.nidaq.s,session.temp.dev,spins{n,ch}, 'Voltage');    
        session.nidaqCh.chIdx_ball(n,ch+2)=session.nidaqCh.chIdx_ball(n,ch+2)+1;
        
    end
end

% activate channel
session.exp.ball = 1;
% conversion factor: % of 3.3V, where 100% = 1.5m/s
%session.ballVars.ballConversionFacor = (1/1.65)*1.5;
session.ball.conversionFactor = 1;
session.ball.yawDrift=1;

