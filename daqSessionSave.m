% daqSessionSave.m saves out the full data file (initialized/created by
% daqSessionClose.m)
% updated 6/18/19 to include 2d ball treadmill data
% updated 3/23/21 (and lots before then) to include classical cond with 2
%       diff stimuli
% edited to include salient stimuli
% edited 2/21/2022 for 2 LEDs 
% updated 3/10/2022 for cleaner and more flexible saving out

function outdata = daqSessionSave
global session % our global variable to store everything

if isfield(session.temp,'fulldata')
    
    %%% mouse and time info 
    % mouse
    outdata.mouse = session.mouse;
    % start time
    outdata.starttime = session.starttime;
    % timestamp
    outdata.timestamp = session.temp.fulldata(:,1);    
    
    %%% treadmill
    % rotary encoder (raw & position)
    if isfield(session.exp,'rotEnc') && session.exp.rotEnc == 1
        signedData = session.temp.fulldata(:,session.nidaqCh.chIdx_rotEnc);  
        outdata.rotaryEncoderRaw = signedData;
        % transformation into position data
        signedData(signedData > session.wheel.signedThreshold) = 2^session.wheel.counterNBits-signedData(signedData > session.wheel.signedThreshold);        
        outdata.rotaryEncoderRotations = signedData/session.wheel.encoderCPR;    
        outdata.rotaryEncoderDistance =  outdata.rotaryEncoderRotations * session.wheel.wheelCirc; % meters 
        outdata.rotaryEncoderVelocity = diff(outdata.rotaryEncoderDistance)./diff(outdata.timestamp); % meters per sec
        outdata.rotaryEncoderVelocity = [outdata.rotaryEncoderVelocity(1) outdata.rotaryEncoderVelocity]; % duplicate the first one to make data lengths the same
    end
    % 2d ball
    if isfield(session.exp,'ball') && session.exp.ball == 1
        % also pre-do the match (this is newer version, where sign and
        % magnitude are sent out separately)
        for n = 1:size(session.nidaqCh.chIdx_ball,1)                                                
            outdata.(['ballSensor' num2str(n) '_x']) = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(n,1));
            outdata.(['ballSensor' num2str(n) '_y']) = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(n,2));
            outdata.(['ballSensor' num2str(n) '_xsign']) = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(n,3));
            outdata.(['ballSensor' num2str(n) '_ysign']) = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(n,4));
        end
        
        if size(session.nidaqCh.chIdx_ball,1)==2        
            ballyaw1= session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,1)) .*(2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,3))>1)-1);
            ballpitch = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,4))>1)-1);
            ballyaw2= session.temp.fulldata(:,session.nidaqCh.chIdx_ball(2,1)) .* (2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(2,3))>1)-1);
            ballroll = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(2,2)) .* (2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(2,4))>1)-1);
            % average the yaw
            if session.ball.yawDrift == 1
                ballyaw = ballyaw1;
            else
                ballyaw = mean([ballyaw1 ballyaw2],2);   
            end
            % display velocity (m/s)           
            outdata.ballYaw = session.ball.conversionFactor*ballyaw;
            outdata.ballPitch = session.ball.conversionFactor*ballpitch;
            outdata.ballRoll = session.ball.conversionFactor*ballroll;     
        else
            ballyaw= session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,1)) .*(2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,3))>1)-1);
            ballpitch = session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*double(session.temp.fulldata(:,session.nidaqCh.chIdx_ball(1,4))>1)-1);           
            % display velocity (m/s)           
            outdata.ballYaw = session.ball.conversionFactor*ballyaw;
            outdata.ballPitch = session.ball.conversionFactor*ballpitch;
            outdata.ballRoll = nan;
        end
    end
    
    %%% now all the other channels that save out as is (no calculations, etc)
    ch2save = fieldnames(session.nidaqCh); % these are in session.nidaqCh
    ch2save = ch2save(strncmp(ch2save,'chIdx',5));
    % ignore the treadmill ones
    if isfield(session.nidaqCh,'chIdx_ball')
        ch2save(strcmp(ch2save,'chIdx_ball')) = []; 
    end
    if isfield(session.nidaqCh,'chIdx_rotEnc')
        ch2save(strcmp(ch2save,'chIdx_rotEnc')) = []; 
    end
    % dictionary of channels and output fields
    chnames = cellfun(@(s) s(strfind(s,'chIdx_')+6:end), ch2save, 'UniformOutput', false);
    ch_map = containers.Map(ch2save,chnames);
    ch_map('chIdx_rew') = 'reward'; % for whatever reason (silly past Mai-Anh), these don't match
    % loop over these and save them out
    for f = 1:numel(ch2save)
        if session.nidaqCh.(ch2save{f}) > 0
            outdata.(ch_map(ch2save{f})) = session.temp.fulldata(:,session.nidaqCh.(ch2save{f}));
        end
    end
    % save this one out for convenience for split/bin: ttlIn1 .* ttlIn470
    if isfield(outdata,'ttlIn1') && isfield(outdata,'ttlIn470')
        outdata.ttlIn1_x_ttlIn470 = outdata.ttlIn1.*outdata.ttlIn470;
    end
    
   
    %%% other variables  
    outdata.experimentSetup = session;
    fields2rm = {'temp','nidaq','handles','virmendata'};
    for f = 1:numel(fields2rm)
        if isfield(outdata.experimentSetup,fields2rm{f})
            outdata.experimentSetup = rmfield(outdata.experimentSetup,fields2rm{f});
        end       
    end
    
    %%% save out
    outdata = outdata;
    save([session.dataFilename '.mat'],'-struct','outdata');
    % delete backup
    daqSessionDeleteBackup;
    
else % if there's an error, save out a file that tells you what the backup columns are
    outstruct = struct;
    outstruct.nidaqCh = session.nidaqCh;
    save([session.dataFilename '_backupcolumns.mat'],'-struct','outstruct');
    disp('could not save data... please see the backup file and backupcolumns.mat file')
    disp(['start time was: ' session.starttime]);
end

