% daqSessionUpdateDataBuffer.m updates the data buffer based on the length
% of the plot window (as set by the user upon initialization)

function daqSessionUpdateDataBuffer(event)

global session % our global variable to store everything

% update data 
session.temp.data = [session.temp.data; event.TimeStamps event.Data];

% clear buffer if we're onto the next window   
if floor(max(session.temp.data(:,1))/session.temp.refreshDisplay)>session.temp.k
    cla(session.handles.axes1) % clear the display axes
    if isfield(session.handles,'axes2')
        cla(session.handles.axes2) % clear the display axes
    end
    session.temp.k = session.temp.k+1; % update the counter
    session.temp.data = session.temp.data(session.temp.data(:,1)>=session.temp.k*session.temp.refreshDisplay,:); % update the buffer
end
    