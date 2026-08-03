% daqSessionPlotEvent_Velocity shows a real-ish time plot of velocity from
% the rotary encoder, pulling data from the session's data buffer (see
% daqSessionUPdateDataBuffer.m), and plotting it on the axes specified by
% the variable 'ax'
%
% updated by Mai-Anh Vu, 6/18/2019 to incorporate 1 sensor
% NEED TO ADD 2nd


function daqSessionPlotEvent_BallVelocity(ax)
    global session % our global variable to store everything
    smoothFactor = 1; % we used to keep this at 51
    hold(ax,'on')
        
    % chunk to display
    x = session.temp.data(:,1);
    xlim1 = session.temp.k*session.temp.refreshDisplay;
    xlim2 = (session.temp.k+1)*session.temp.refreshDisplay;
    
    if size(session.nidaqCh.chIdx_ball,1)==2
        
        %dyaw1= session.temp.data(:,session.nidaqCh.chIdx_ball(1,1)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(1,3))-1);
        %dpitch = session.temp.data(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(1,4))-1);
        %dyaw2= session.temp.data(:,session.nidaqCh.chIdx_ball(2,1)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(2,3))-1);
        %droll = session.temp.data(:,session.nidaqCh.chIdx_ball(2,2)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(2,4))-1);
        
        dyaw1= session.temp.data(:,session.nidaqCh.chIdx_ball(1,1)) .*(2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(1,3))>1)-1);
        dpitch = session.temp.data(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(1,4))>1)-1);
        dyaw2= session.temp.data(:,session.nidaqCh.chIdx_ball(2,1)) .* (2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(2,3))>1)-1);
        droll = session.temp.data(:,session.nidaqCh.chIdx_ball(2,2)) .* (2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(2,4))>1)-1);
        % average the yaw        
        if session.ball.yawDrift == 1
            dyaw = dyaw1;
        else
            dyaw = mean([dyaw1 dyaw2],2);   
        end
    else
        %dyaw= session.temp.data(:,session.nidaqCh.chIdx_ball(1,1)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(1,3))-1);
        %dpitch = session.temp.data(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*session.temp.data(:,session.nidaqCh.chIdx_ball(1,4))-1);        
        dyaw= session.temp.data(:,session.nidaqCh.chIdx_ball(1,1)) .*(2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(1,3))>1)-1);
        dpitch = session.temp.data(:,session.nidaqCh.chIdx_ball(1,2)) .* (2*double(session.temp.data(:,session.nidaqCh.chIdx_ball(1,4))>1)-1);
        droll = zeros(size(dpitch));
    end
    % conversion factor
    dyaw = session.ball.conversionFactor*dyaw;
    dpitch = session.ball.conversionFactor*dpitch;
    droll = session.ball.conversionFactor*droll;   
       
    if length(x)>length(dpitch)
        dpitch = [nan; dpitch];
        dyaw = [nan; dyaw];
        droll = [nan; droll];
    end    
    plot(ax,x,smooth(dpitch,smoothFactor),'-r','LineWidth',2,'Color',[0.6350 0.0780 0.1840]) % color = lines7 (red)
    plot(ax,x,smooth(dyaw,smoothFactor),'-r','LineWidth',2,'Color',[0.3010 0.7450 0.9330]) % color = lines6 (light blue)
    plot(ax,x,smooth(droll,smoothFactor),'-r','LineWidth',2,'Color',[0 .5 0]) % color = darker green
    if ~isempty(x)
        set(ax,'XLim',[xlim1 xlim2],'YLim',[-3.3 3.3])      
        plot(ax,get(ax,'XLim'),[0 0],'k')
    end
    ylabel(ax,'velocity (V)')      
    
end
