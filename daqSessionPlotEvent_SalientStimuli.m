% daqSessionPlotEvent_auditoryPavlovian shows a real-ish time plot of 
% sound stimuli from the auditory pavloain task the delay, pulling data 
% from the session's data buffer (see daqSessionUpdateDataBuffer.m), and 
% plotting it on the axes specified by the variable 'ax' (can put on as
% many axes as desired)
%
% updated by Mai-Anh Vu, 12/31/21


function daqSessionPlotEvent_SalientStimuli(varargin)
    global session % our global variable to store everything
    
    for v = 1:length(varargin)
        ax = varargin{v};
        hold(ax,'on')

        % chunk to display
        x = session.temp.data(:,1);
        xlim1 = session.temp.k*session.temp.refreshDisplay;
        xlim2 = (session.temp.k+1)*session.temp.refreshDisplay;    
        ylim = get(ax,'YLim');        
        if isfield(session.exp,'stimulus_sound')       
            y1 = ones(size(x))*ylim(1);
            y1(session.temp.data(:,session.nidaqCh.chIdx_stimulus_sound)==1) = ylim(2);
            plot(ax,x,y1,'-','Color',[0 0.4470 0.7410],'LineWidth',2,'LineStyle',':') % blue (lines1)
        end        
        if isfield(session.exp,'stimulus_led')
            y2 = ones(size(x))*ylim(1);
            y2(session.temp.data(:,session.nidaqCh.chIdx_stimulus_led)==1) = ylim(2);
            % LED2 
            if isfield(session.nidaqCh,'chIdx_stimulus_led2')
                y2(session.temp.data(:,session.nidaqCh.chIdx_stimulus_led2)>0) = ylim(2);
            end
            plot(ax,x,y2,'-','Color',[0 0.4470 0.7410],'LineWidth',2,'LineStyle',':') % orange (lines(2)
        end        
        if isfield(session.exp,'stimulus_tactile')       
            y3 = ones(size(x))*ylim(1);
            y3(session.temp.data(:,session.nidaqCh.chIdx_stimulus_tactile)==1) = ylim(2);
            plot(ax,x,y3,'-','Color',[0.301 0.745 0.933],'LineWidth',2,'LineStyle',':') % light blue (lines(6)
        end
        
        
        
        if ~isempty(x)
            set(ax,'XLim',[xlim1 xlim2],'YLim',[-1 1])
            plot(ax,get(ax,'XLim'),[0 0],'k')
        end        
        set(ax,'YLim',ylim);
    end
end
