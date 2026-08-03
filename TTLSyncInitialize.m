% add a digital output channel to our data acquisition session for sending
% TTL pulses for syncing with the 2p  recording
% updated 8/6/20 to use second breakout
% updated 3/10/22 to move some pins around

global session % our global variable to store everything

%%% sending TTL pulses out

% % add digital output channel (2nd breakout J46: P0.26) to send TTL pulses 
% [session.temp.ch_ttl,session.nidaqCh.outIdx_ttl] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line26','OutputOnly'); 
% add digital output channel (breakout #1 J37: P2.0) to send TTL pulses 
[session.temp.ch_ttl,session.nidaqCh.outIdx_ttl] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port2/Line0','OutputOnly'); 
session.nidaqCh.outIdx_ttl=session.nidaqCh.outIdx_ttl+1;

% % add digital input channel (breakout #2 J47: P0.27) to record TTL pulses
% [~,session.nidaqCh.chIdx_ttlOut] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line27','InputOnly');
% add digital input channel (breakout #1 J48: P0.7) to record TTL pulses
[~,session.nidaqCh.chIdx_ttlOut] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line7','InputOnly');
session.nidaqCh.chIdx_ttlOut=session.nidaqCh.chIdx_ttlOut+1;

% TTL pulse counter
session.TTLcountOut = 0;

%%% reading TTL pulses in: add both digital input channels

% add digital input channel (J49: P0.2) to record source 1 TTLs
[~,session.nidaqCh.chIdx_ttlIn1] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line2','InputOnly');
session.nidaqCh.chIdx_ttlIn1=session.nidaqCh.chIdx_ttlIn1+1;

% add digital input channel (J16: P0.6) to record source 2 TTLs
[~,session.nidaqCh.chIdx_ttlIn2] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line6','InputOnly');
session.nidaqCh.chIdx_ttlIn2=session.nidaqCh.chIdx_ttlIn2+1;

% now try adding TTLs 3 & 4 (use try/catch in case there isn't a second
% breakout board)
try
    % add digital input channel (J17: P0.9) to record ttlIn3
    [~,session.nidaqCh.chIdx_ttlIn3] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line9','InputOnly');
    session.nidaqCh.chIdx_ttlIn3=session.nidaqCh.chIdx_ttlIn3+1;
    
    % add digital input channel (J51: P0.13) to record ttlIn4
    [~,session.nidaqCh.chIdx_ttlIn4] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line13','InputOnly');
    session.nidaqCh.chIdx_ttlIn4=session.nidaqCh.chIdx_ttlIn4+1;

catch
    disp('not adding ttlIn3 & ttlIn4: need 2nd breakout board for that')
end

%%% add digital input channel (J19: P0.4) ro record cor disch LED1 (407)
[~,session.nidaqCh.chIdx_ttlIn470] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line4','InputOnly');
session.nidaqCh.chIdx_ttlIn470=session.nidaqCh.chIdx_ttlIn470+1;

%%% digital square switch
if isfield(session.exp,'squareSwitch') && session.exp.squareSwitch == 1
    try
        % add ouput channel (J47 breakout board #2 P0.26)
        [session.temp.ch_squareSwitch,session.nidaqCh.outIdx_squareSwitch] = addDigitalChannel(session.nidaq.s2,session.temp.dev,'Port0/Line26','OutputOnly'); 
        session.nidaqCh.outIdx_squareSwitch = session.nidaqCh.outIdx_squareSwitch + 1;
        % add input channel to record square pulse (J48 breakout board #2 P0.27)
        [~,session.nidaqCh.chIdx_squareSwitch] = addDigitalChannel(session.nidaq.s,session.temp.dev,'Port0/Line27','InputOnly');
        session.nidaqCh.chIdx_squareSwitch=session.nidaqCh.chIdx_squareSwitch+1;
        % add a listener
        session.nidaq.lh4 = session.nidaq.s.addlistener('DataAvailable', @(src,event) TTLSquareSwitch);
        session.temp.digSquareOn = 0; % initialize
    catch exception
        disp('sorry, need 2nd breakout board for 5V Square function')
        disp('will disable this function and continue.')
        session.exp.squareSwitch = 0;
    end
end