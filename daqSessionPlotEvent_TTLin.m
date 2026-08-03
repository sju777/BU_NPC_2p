% daqSessionPlotEvent_TTL shows a real-ish time plot of TTL signals
% received, pulling data from the session's data buffer (see
% daqSessionUPdateDataBuffer.m), and plotting it on the axes specified by
% the variable 'ax' (can put on as many axes as desired)
%
% updated by Mai-Anh Vu, 7/14/2020


function daqSessionPlotEvent_TTLin(varargin)
    global session % our global variable to store everything
    decimationFactor = 10; % plot every 10th TTL
    for v = 1:length(varargin)
        ax = varargin{v};
        hold(ax,'on')

        % chunk to display
        x = session.temp.data(:,1);        
        xlim1 = session.temp.k*session.temp.refreshDisplay;
        xlim2 = (session.temp.k+1)*session.temp.refreshDisplay;
    
        ylim = get(ax,'YLim');
        y1 = session.temp.data(:,session.nidaqCh.chIdx_ttlIn1);
        y1 = [0; diff(y1)];
        y1(y1==-1)=0;        
        ttls1 = x(y1==1);
        ttls1 = ttls1(1:decimationFactor:length(ttls1));                
        y2 = session.temp.data(:,session.nidaqCh.chIdx_ttlIn2);        
        y2 = [0; diff(y2)];        
        y2(y2==-1)=0;
        ttls2 = x(y2==1);
        ttls2 = ttls2(1:decimationFactor:length(ttls2));        
        
        if session.nidaqCh.chIdx_ttlIn3>0
            y3 = session.temp.data(:,session.nidaqCh.chIdx_ttlIn3);            
            y3 = [0; diff(y3)];
            y3(y3==-1) = 0;
            ttls3 = x(y3==1);            
            ttls3 = ttls3(1:decimationFactor:length(ttls3));
            y4 = session.temp.data(:,session.nidaqCh.chIdx_ttlIn4);
            y4 = [0; diff(y4)];
            y4(y4==-1) = 0;
            ttls4 = x(y4==1);
            ttls4 = ttls4(1:decimationFactor:length(ttls4));
        else
            ttls3 = [];
            ttls4 = [];
        end
        for i = 1:numel(ttls1)
            plot(ax,[ttls1(i) ttls1(i)],ylim,'--','Color',[0.9290 0.6940 0.1250]); % color = lines3
        end
        for i = 1:numel(ttls2)
            plot(ax,[ttls2(i) ttls2(i)],ylim,'--','Color',.8*[0.9290 0.6940 0.1250]); % color = lines3*.8
        end
        for i = 1:numel(ttls3)
            plot(ax,[ttls3(i) ttls3(i)],ylim,':','Color',.9*[0.9290 0.6940 0.1250]); % color = lines3*.9
        end
        for i = 1:numel(ttls4)
            plot(ax,[ttls4(i) ttls4(i)],ylim,':','Color',.7*[0.9290 0.6940 0.1250]); % color = lines3*.7
        end
        
        if ~isempty(x)
            set(ax,'XLim',[xlim1 xlim2],'YLim',[-1 1])
            plot(ax,get(ax,'XLim'),[0 0],'k')
        end        
        set(ax,'YLim',ylim);
    end
end