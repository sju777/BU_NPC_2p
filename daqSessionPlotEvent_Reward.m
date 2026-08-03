% daqSessionPlotEvent_Reward shows a real-ish time plot of reward from
% the solenoid TTL, pulling data from the session's data buffer (see
% daqSessionUPdateDataBuffer.m), and plotting it on the axes specified by
% the variable 'ax' (can put on as many axes as desired)
%
% updated by Mai-Anh Vu, 10/29/2018


function daqSessionPlotEvent_Reward(varargin)
    global session % our global variable to store everything
    
    for v = 1:length(varargin)
        ax = varargin{v};
        hold(ax,'on')

        % chunk to display
        x = session.temp.data(:,1);
        xlim1 = session.temp.k*session.temp.refreshDisplay;
        xlim2 = (session.temp.k+1)*session.temp.refreshDisplay;
    
        ylim = get(ax,'YLim');
        y = session.temp.data(:,session.nidaqCh.chIdx_rew);
        yL = session.temp.data(:,session.nidaqCh.chIdx_lick);
        y(y==0) = ylim(1);
        y(y==1) = ylim(2);
        yL(yL==0) = ylim(1);
        yL(yL==1) = ylim(2);
        plot(ax,x,y,'-g','Color',[0.4660 0.6740 0.1880]) % color = lines5
        plot(ax,x,yL,'-k','Color',[0.4940 0.1840 0.5560]) % color = lines4
        if ~isempty(x)
            set(ax,'XLim',[xlim1 xlim2],'YLim',[-1 1])
            plot(ax,get(ax,'XLim'),[0 0],'k')
        end        
        set(ax,'YLim',ylim);
    end
end
