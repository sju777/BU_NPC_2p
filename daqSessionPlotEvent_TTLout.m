% daqSessionPlotEvent_TTL shows a real-ish time plot of pulses from
% the syncing TTL, pulling data from the session's data buffer (see
% daqSessionUPdateDataBuffer.m), and plotting it on the axes specified by
% the variable 'ax' (can put on as many axes as desired)
%
% updated by Mai-Anh Vu, 12/10/2018


function daqSessionPlotEvent_TTLout(varargin)
    global session % our global variable to store everything
    
    for v = 1:length(varargin)
        ax = varargin{v};
        hold(ax,'on')

        % chunk to display
        x = session.temp.data(:,1);
        xlim1 = session.temp.k*session.temp.refreshDisplay;
        xlim2 = (session.temp.k+1)*session.temp.refreshDisplay;
    
        ylim = get(ax,'YLim');
        y = session.temp.data(:,session.nidaqCh.chIdx_ttlOut);
        y = [0; diff(y)];
        y(y==-1)=0;
        ttls = x(y==1);
        for i = 1:sum(y)
            plot(ax,[ttls(i) ttls(i)],ylim,':k','Color',[0.8500 0.3250 0.0980],'LineWidth',2); % color = lines2
        end
        %y(y==0) = ylim(1);
        %y(y==1) = ylim(2);        
        %plot(ax,x,y,'-k')
        
        if ~isempty(x)
            set(ax,'XLim',[xlim1 xlim2],'YLim',[-1 1])
            plot(ax,get(ax,'XLim'),[0 0],'k')
        end        
        set(ax,'YLim',ylim);
    end
end
