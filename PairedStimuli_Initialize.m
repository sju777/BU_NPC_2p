% initialize inputs and outputs for the audio / airpuff / paired task
% Modeled after SalientStimuli_Initialize.m (Mai-Anh Vu, 11/9/2021).
%
% Unlike SalientStimuli_Initialize.m (which hardcodes each channel's
% digital/analog type and DAQ port string), every channel actually used
% here (reward, lick, the two stimulus channels, TTL sync, spare TTL ins)
% is created dynamically from session.exp.daqChannelMap -- the full NI
% PCIe-6321 channel inventory (16 AI, 2 AO, 24 digital I/O, 4 counters)
% you can browse/edit in the PairedStimuli GUI's "DAQ Channels" table:
% reassign any channel's role (Reward/Lick/Audio/Airpuff/TTL Sync/TTL
% In/Unused), and for digital lines, its Direction. See PairedStimuli.m's
% buildDefaultChannelMap/daq_channel_table_CellEditCallback for how that
% table is built and edited. Rows left "Unused" don't consume a DAQ
% channel at all.
%
% The ball (treadmill) and photometry-excitation-LED channels are NOT
% part of this dynamic assignment -- they're special multi-channel
% systems still created by BallInitialize.m / LEDInitialize.m exactly as
% in SalientStimuli.m. They're only *listed* in the DAQ Channels table
% for reference. Unlike the NI 6259 this task previously targeted, the
% PCIe-6321 has all 4 counter/timers (ctr0-ctr3) needed by
% LEDInitialize.m's 3rd-LED/camera-trigger, so those rows are no longer
% flagged as unavailable (though the Photometry LEDs feature itself isn't
% exposed in this GUI's Task Setup either way).
%
% One exception to the generic per-row creation above: if Audio's output
% channel is analog, it's NOT added to the shared on-demand session
% (session.nidaq.s2) like everything else -- it gets its own dedicated
% background-streaming session (session.nidaq.s4) so PairedStimuli_Run.m
% can send an actual sine wave (see generateCurrentSound) rather than
% just a static on/off level. If Audio's output channel is digital, it
% behaves as before: a simple TTL marker on session.nidaq.s2, with the
% actual tone played through this computer's speakers.

function PairedStimuli_Initialize
global session % our global variable to store everything

% add every assigned "simple" channel (reward, lick, stimulus x2, TTL
% sync, spare TTL ins, or anything else you assigned in the DAQ Channels
% table) using whatever digital/analog type + port that channel actually
% is; rows still marked "Unused" are skipped entirely.
session.nidaqCh.mapIdx = struct();
for i = 1:numel(session.exp.daqChannelMap)
    row = session.exp.daqChannelMap(i);
    if ~row.editable || strcmp(row.assignment,'Unused')
        continue % ball/photometry (fixed) or unassigned channels
    end
    if strcmp(row.assignment,'Audio') && strcmp(row.direction,'out') && strcmpi(row.type,'analog')
        continue % handled separately below: needs its own background-
                  % streaming session to send an actual sine wave, not a
                  % slot on the shared on-demand session.nidaq.s2
    end
    try
        if strcmpi(row.type,'digital')
            if strcmp(row.direction,'out')
                [~,idx] = addDigitalChannel(session.nidaq.s2,session.temp.dev,row.port,'OutputOnly');
            else
                [~,idx] = addDigitalChannel(session.nidaq.s,session.temp.dev,row.port,'InputOnly');
            end
        else % analog
            if strcmp(row.direction,'out')
                [~,idx] = addAnalogOutputChannel(session.nidaq.s2,session.temp.dev,row.port,'Voltage');
            else
                [~,idx] = addAnalogInputChannel(session.nidaq.s,session.temp.dev,row.port,'Voltage');
            end
        end
    catch err
        error('PairedStimuli:channelSetup', ...
            'Could not add channel "%s" (%s, %s, port "%s"): %s', ...
            row.label, row.direction, row.type, row.port, err.message);
    end
    session.nidaqCh.mapIdx.(row.key) = idx+1;
end

% resolve the semantic names the rest of the codebase expects
% (daqSessionInitializeOutputs.m, daqSessionPlotEvent_SalientStimuli.m,
% daqSessionSave.m, PairedStimuli_Run.m) based on each row's current
% Assignment, whichever physical channel that currently is
session.nidaqCh.outIdx_rew = resolveIdx(session,'Reward','out');
session.nidaqCh.chIdx_rew = resolveIdx(session,'Reward','in');
session.nidaqCh.chIdx_lick = resolveIdx(session,'Lick','in');
session.exp.rew=1;
session.exp.lick=1;

audioOutRow = findChannelRow(session.exp.daqChannelMap,'Audio','out');
audioInRow  = findChannelRow(session.exp.daqChannelMap,'Audio','in');
session.nidaqCh.chIdx_stimulus_sound  = session.nidaqCh.mapIdx.(audioInRow.key);
session.exp.stimulus_sound = 1;
if strcmpi(audioOutRow.type,'analog')
    % Audio is assigned an analog channel: send the actual sine wave to
    % the DAQ (see generateCurrentSound in PairedStimuli_Run.m) via a
    % dedicated background-streaming session -- named s4 so the shared
    % daqSessionClose.m (which stops/zeroes any session.nidaq.s3..s10)
    % cleans it up automatically, same as SalientStimuli.m's LED session.
    session.nidaq.s4 = daq.createSession('ni');
    session.nidaq.s4.Rate = 200000; % samples/second -- ample headroom for audible tone frequencies
    [~,audioAOIdx] = addAnalogOutputChannel(session.nidaq.s4,session.temp.dev,audioOutRow.port,'Voltage');
    session.nidaqCh.mapIdx.(audioOutRow.key) = audioAOIdx+1;
    session.nidaq.s4.queueOutputData(zeros(500,1)); % send 0V in case
    session.nidaq.s4.startBackground();
    session.exp.audioIsAnalogOut = true;
    session.nidaqCh.outIdx_stimulus_sound = NaN; % not part of session.nidaq.s2 -- unused in this mode
else
    session.nidaqCh.outIdx_stimulus_sound = session.nidaqCh.mapIdx.(audioOutRow.key);
    session.exp.audioIsAnalogOut = false;
end
session.exp.stimAudioOnValue = channelOnValue(audioOutRow); % only used in the digital (TTL marker) case

airpuffOutRow = findChannelRow(session.exp.daqChannelMap,'Airpuff','out');
airpuffInRow  = findChannelRow(session.exp.daqChannelMap,'Airpuff','in');
session.nidaqCh.outIdx_stimulus_tactile = session.nidaqCh.mapIdx.(airpuffOutRow.key);
session.nidaqCh.chIdx_stimulus_tactile  = session.nidaqCh.mapIdx.(airpuffInRow.key);
session.exp.stimulus_tactile = 1;
session.exp.stimAirpuffOnValue = channelOnValue(airpuffOutRow);

ttlSyncOutRow = findChannelRow(session.exp.daqChannelMap,'TTL Sync','out');
ttlSyncInRow  = findChannelRow(session.exp.daqChannelMap,'TTL Sync','in');
session.nidaqCh.outIdx_ttl = session.nidaqCh.mapIdx.(ttlSyncOutRow.key);
session.nidaqCh.chIdx_ttlOut = session.nidaqCh.mapIdx.(ttlSyncInRow.key);

ttlInRows = findAllChannelRows(session.exp.daqChannelMap,'TTL In','in');
ttlInFieldNames = {'chIdx_ttlIn1','chIdx_ttlIn2','chIdx_ttlIn3','chIdx_ttlIn4','chIdx_ttlIn470'};
for i = 1:min(numel(ttlInRows),numel(ttlInFieldNames))
    session.nidaqCh.(ttlInFieldNames{i}) = session.nidaqCh.mapIdx.(ttlInRows(i).key);
end

% timers & listeners
session.temp.currentTrial = 1;
session.nidaq.lh3 = session.nidaq.s.addlistener('DataAvailable', @(src,event) PairedStimuli_Run);

% keep track of reward volume delivered (uL)
session.rew.totalVolDelivered = 0;
session.rew.rewCounts = [0 0 0];
session.rew.rewSize = [];

session.temp.stimulusOn = 0; % stimulus is currently off
session.temp.airpuffPulseIdx = 0; % 0 = airpuff pulse train is not running


% --- local helpers -------------------------------------------------

function idx = resolveIdx(session, assignment, direction)
row = findChannelRow(session.exp.daqChannelMap, assignment, direction);
idx = session.nidaqCh.mapIdx.(row.key);

function row = findChannelRow(map, assignment, direction)
for i = 1:numel(map)
    if strcmp(map(i).assignment,assignment) && strcmp(map(i).direction,direction)
        row = map(i);
        return
    end
end
error('PairedStimuli:channelSetup', ...
    'No channel is assigned to "%s" (%s). Fix this in the DAQ Channels table.', assignment, direction)

function rows = findAllChannelRows(map, assignment, direction)
rows = [];
for i = 1:numel(map)
    if strcmp(map(i).assignment,assignment) && strcmp(map(i).direction,direction)
        rows = [rows map(i)];
    end
end

% the value written into the shared digital output vector to turn this
% channel "on": logical 1 for a digital channel, or the configured
% amplitude (in volts) for an analog channel
function v = channelOnValue(row)
if strcmpi(row.type,'analog')
    v = row.amplitude;
    if isnan(v) || v==0
        v = 5; % sane default if no amplitude was configured
    end
else
    v = 1;
end
