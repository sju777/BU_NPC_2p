
% daqSessionInitialize intializes the data acquisition session
% 
% updated by Mai-Anh Vu, 10/29/18
% updated by Mai-Anh Vu, 06/18/19 to include 2d ball
% updated by Mai-Anh Vu, 3/10/22 to clean up initialization and save


global session

% create a data acquisition session for recording
session.nidaq.s = daq.createSession('ni');
session.nidaq.s.Rate = 2000; % samples/second (here we set to 2kHz)
session.nidaq.s.IsContinuous=1; % continuous acquisition

% look for the device - we have a NI PCIe-6259
deviceModel = 'PCIe-6259';
devices = daq.getDevices;
session.temp.dev = '';
d = 1;
while isempty(session.temp.dev)
    thisDev = devices(d);
    if strncmp(thisDev.Model,deviceModel,length(deviceModel))
        session.temp.dev=thisDev.ID;
    end
    d = d+1;
end
    
% create another session for outputs (reward, TTL, etc)
session.nidaq.s2 = daq.createSession('ni');

% initialize data output
session.temp.k = 0; % k for data plotting
session.temp.data = []; % data for plotting

% add a listener for continuous data save
session.temp.fid1 = fopen([session.dataFilename '_backup.txt'],'w');
session.nidaq.lh1 = session.nidaq.s.addlistener('DataAvailable', @(src,event) daqSessionLogData(src, event, session.temp.fid1));

% initialize this if necessary
if ~isfield(session,'exp')
    session.exp = struct;
end
session.exp.squareSwitch = 0; % i don't think this is necessary, but juuust in case
