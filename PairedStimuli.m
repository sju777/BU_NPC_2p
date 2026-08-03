% PairedStimuli GUI for running a salient-stimulus experiment with three
% trial types: audio (tone) only, airpuff (whisker) only, and paired
% (simultaneous audio + airpuff) stimulation.
%
% Audio has its own Frequency (kHz, per configured tone) and Duration
% (s, shared) parameters in the Audio panel. If the DAQ Channels table
% assigns Audio to an ANALOG output, those parameters drive an actual
% sine wave sent to the DAQ (session.nidaq.s4, see PairedStimuli_
% Initialize.m / PairedStimuli_Run.m); if Audio is assigned a DIGITAL
% output, the tone instead plays through this computer's speakers, with
% just a TTL marker sent to the DAQ (the original behavior).
%
% Modeled after SalientStimuli.m (Mai-Anh Vu, 10/2/2021): same overall
% session.exp/session.temp/session.nidaq bookkeeping, and calls most of
% the same shared acquisition functions:
%   daqSessionInitialize, BallInitialize,
%   daqSessionInitializeDataBuffer, daqSessionInitializeOutputs,
%   daqSessionPlotEvent_SalientStimuli, daqSessionRecord, daqSessionClose,
%   daqSessionSave, daqSessionDeleteBackup
% (TTLSyncInitialize is one exception -- see the DAQ Channels note below
% for why this GUI doesn't call it. LEDInitialize/the photometry-LED
% feature from SalientStimuli.m has been dropped entirely for this task.)
% The LED-cue task setup from SalientStimuli.m is replaced with an airpuff
% (whisker) task setup. Only PairedStimuli_Initialize.m and
% PairedStimuli_Run.m are new companion files (paralleling
% SalientStimuli_Initialize.m / SalientStimuli_Run.m).
%
% This GUI is split across TWO windows:
%   Window 1 ("Setup", handles.figure1): Save Output, DAQ Channels, Task
%     Setup, Runtime (ITI).
%   Window 2 ("Trial Block & Run", handles.figure2): Trial Block (build/
%     edit/preview the trial sequence) and Run (Setup OK/Start/Stop) plus
%     the live acquisition plots.
% Both windows share one merged `handles` struct (guidata is synced on
% both figures), so any callback can reach controls in either window
% regardless of which window triggered it.
%
% This version adds a "Trial Block" panel: set the number of trials in
% the block (300+ trials supported), auto-generate a randomly-ordered
% audio/airpuff/paired assignment for every trial (fixed composition:
% 10% audio-only, 10% airpuff-only, 80% paired), hand-edit any trial's
% assignment in an editable table, and visually confirm the whole block
% (red = audio, blue = airpuff, purple = paired) before hardware setup /
% Start.
%
% It also adds a "DAQ Channels" panel: a table listing every DAQ channel
% this rig currently uses (reward, lick, the two stimulus channels, TTL
% sync, spare TTL ins, the ball treadmill, and the photometry LEDs), each
% tagged with its current digital/analog type and port/channel ID. The
% "simple" channels (reward, lick, the 2 stimulus channels, TTL sync,
% spare TTL ins) are editable: flip Type between digital/analog, edit the
% Port, or change which stimulus (Audio/Airpuff) a channel delivers --
% changing one stimulus channel's assignment swaps it with the other, so
% exactly one channel is always Audio and the other Airpuff. The ball and
% photometry rows are informational only (they're multi-channel systems
% still owned by BallInitialize.m / LEDInitialize.m). Because the two
% stimulus channels and TTL sync/spare-TTL-in channels are now configured
% through this table, PairedStimuli_Initialize.m creates them dynamically
% and TTLSyncInitialize.m is no longer called for this GUI (it's still
% used, unchanged, by SalientStimuli.m).
%
% A "Presets" panel (Window 1, under Save Output) lets you save the
% current Task Setup / Runtime / DAQ Channels configuration (audio/
% airpuff/paired settings, tone list, airpuff/stim durations, ITI
% settings, block size, and the full DAQ channel map) TOGETHER WITH
% Window 2's generated Trial Block (session.exp.trials, including any
% hand-edits made in the block table) to a named .mat file under
% PairedStimuli_Presets/ next to this script, and reload both windows'
% state at once later via a dropdown + Load button. Save Output
% (path/filename) is the only thing NOT part of a preset -- that's
% per-session. If a preset was saved before a block was ever generated,
% loading it just leaves Window 2 empty as before.
%
% Unlike SalientStimuli.m (built with GUIDE, backed by a .fig file), this
% GUI is built programmatically (no .fig) so it has no external binary
% dependency, but the callback functions below follow the same
% (hObject, eventdata, handles) convention as GUIDE-generated callbacks.
% All panels/controls use normalized units, so the whole window (and
% every section in it) resizes smoothly when the figure is resized.

function varargout = PairedStimuli(varargin)
global session % our global variable to store everything
% `session` is a MATLAB global, so it can persist across a previous run
% (e.g. one that errored out, or was closed without going through the
% Stop button's "Start another session?" -> clear global path). Reset it
% here so every fresh launch starts clean, regardless of what a prior
% run left behind (e.g. session.exp.tone left as 0, which would make the
% dot-indexing assignment in PairedStimuli_OpeningFcn below fail).
session = struct();

handles = PairedStimuli_LayoutFcn();
PairedStimuli_OpeningFcn(handles.figure1, [], handles);

if nargout
    varargout{1} = PairedStimuli_OutputFcn(handles.figure1, [], guidata(handles.figure1));
end


% --- Executes just before PairedStimuli is made visible.
function PairedStimuli_OpeningFcn(hObject, eventdata, handles)
% hObject    handle to figure
% eventdata  reserved
% handles    structure with handles and user data (see GUIDATA)

handles.output = hObject;
guidata(hObject, handles);
guidata(handles.figure2, handles); % keep window 2's guidata store in sync

global session
session.exp.tone.tone1.freq = str2double(get(handles.tone_freq,'String'));
session.exp.tone.tone1.vol = str2num(get(handles.tone_vol,'String'));

session.exp.daqChannelMap = buildDefaultChannelMap();
populateDaqChannelTable(handles);

refreshPresetList(handles);

updateAudioControlsEnable(handles);
updateAirpuffControlsEnable(handles);
updateBlockPreview(handles); % shows the "generate a block first" placeholder


% --- Outputs from this function are returned to the command line.
function output = PairedStimuli_OutputFcn(hObject, eventdata, handles)
global session
session.handles = handles;
output = session;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SAVING OUTPUT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in save_path_button.
function save_path_button_Callback(hObject, eventdata, handles)
set(handles.save_path,'String',uigetdir(get(handles.save_path,'String')));

function save_path_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of save_path as text

function filename_prefix_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of filename_prefix as text


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% PRESETS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save/load the Task Setup + Runtime + DAQ Channels configuration (Window
% 1) TOGETHER WITH the generated Trial Block (Window 2, session.exp.
% trials -- including any hand-edits made in the block table) to/from a
% single named .mat file, so one preset captures both windows and you
% don't have to re-enter the same protocol or regenerate/re-edit the same
% block by hand every session. Save Output (path/filename) is the only
% thing deliberately NOT included -- that's per-session. If a preset was
% saved before any block was generated, loading it leaves the block empty
% (same as before) and you just click "Generate Block" (Window 2).

% folder presets are stored in, next to this script (created on first save)
function d = presetDir()
d = fullfile(fileparts(mfilename('fullpath')),'PairedStimuli_Presets');

% helper: rescan presetDir() and refresh the dropdown list
function refreshPresetList(handles)
d = presetDir();
names = {};
if exist(d,'dir')
    files = dir(fullfile(d,'*.mat'));
    names = cellfun(@(s) s(1:end-4), {files.name}, 'UniformOutput', false);
end
if isempty(names)
    set(handles.preset_list,'String',{'(no presets saved yet)'},'Value',1);
else
    set(handles.preset_list,'String',sort(names),'Value',1);
end

% --- Executes on button press in save_preset.
function save_preset_Callback(hObject, eventdata, handles)
global session
answer = inputdlg('Preset name:','Save Preset',1,{'my_preset'});
if isempty(answer) || isempty(strtrim(answer{1}))
    return
end
name = regexprep(strtrim(answer{1}),'[^\w\-]','_'); % sanitize for a filename

preset = struct();
preset.audio_yes = get(handles.audio_yes,'Value');
preset.airpuff_yes = get(handles.airpuff_yes,'Value');
preset.paired_yes = get(handles.paired_yes,'Value');
preset.tone_n = get(handles.tone_n,'String');
preset.audio_dur = get(handles.audio_dur,'String');
preset.tone = session.exp.tone; % full per-tone freq/vol config, not just the one shown
preset.airpuff_pulse_len = get(handles.airpuff_pulse_len,'String');
preset.airpuff_n_pulses = get(handles.airpuff_n_pulses,'String');
preset.airpuff_total_time = get(handles.airpuff_total_time,'String');
preset.stim_dur = get(handles.stim_dur,'String');
preset.iti_min = get(handles.iti_min,'String');
preset.iti_max = get(handles.iti_max,'String');
preset.iti_initial = get(handles.iti_initial,'String');
preset.n_trials = get(handles.n_trials,'String');
preset.daqChannelMap = session.exp.daqChannelMap;
if isfield(session.exp,'trials') && istable(session.exp.trials)
    preset.trials = session.exp.trials; % Window 2's generated block (incl. any hand-edits), saved as-is
else
    preset.trials = table(); % no block generated yet -- save an empty placeholder
end

d = presetDir();
if ~exist(d,'dir')
    mkdir(d);
end
save(fullfile(d,[name '.mat']),'-struct','preset');

refreshPresetList(handles);
idx = find(strcmp(get(handles.preset_list,'String'),name),1);
if ~isempty(idx)
    set(handles.preset_list,'Value',idx);
end
msgbox(sprintf('Saved preset "%s".',name),'Preset saved');

% --- Executes on button press in load_preset.
function load_preset_Callback(hObject, eventdata, handles)
global session
names = get(handles.preset_list,'String');
name = names{get(handles.preset_list,'Value')};
if strcmp(name,'(no presets saved yet)')
    warndlg('No preset selected. Use "Save As" first.','Cannot load preset');
    return
end
fpath = fullfile(presetDir(),[name '.mat']);
if ~exist(fpath,'file')
    errordlg(sprintf('Preset file not found: %s',fpath),'Cannot load preset');
    refreshPresetList(handles);
    return
end
preset = load(fpath);

set(handles.audio_yes,'Value',preset.audio_yes);
set(handles.airpuff_yes,'Value',preset.airpuff_yes);
set(handles.paired_yes,'Value',preset.paired_yes);
set(handles.tone_n,'String',preset.tone_n);
if isfield(preset,'audio_dur')
    set(handles.audio_dur,'String',preset.audio_dur);
else
    set(handles.audio_dur,'String','2'); % older preset format predates this field
end
session.exp.tone = preset.tone;
ensureToneStruct(); % repair session.exp.tone if this preset predates a fix and saved it as 0/invalid
toneFields = fieldnames(session.exp.tone);
set(handles.tone_list,'String',toneFields,'Value',1);
set(handles.tone_freq,'String',num2str(session.exp.tone.(toneFields{1}).freq));
set(handles.tone_vol,'String',strjoin(cellstr(num2str(session.exp.tone.(toneFields{1}).vol'))',','));
if isfield(preset,'airpuff_pulse_len')
    set(handles.airpuff_pulse_len,'String',preset.airpuff_pulse_len);
    set(handles.airpuff_n_pulses,'String',preset.airpuff_n_pulses);
    if isfield(preset,'airpuff_total_time')
        set(handles.airpuff_total_time,'String',preset.airpuff_total_time);
    else
        % older preset format saved pulse length/IPI/# of pulses instead
        % of pulse length/# of pulses/total time -- convert
        pulseLen = str2double(preset.airpuff_pulse_len);
        nPulses = round(str2double(preset.airpuff_n_pulses));
        ipi = str2double(preset.airpuff_ipi);
        totalTime = nPulses*pulseLen + max(0,nPulses-1)*ipi;
        set(handles.airpuff_total_time,'String',num2str(totalTime));
    end
elseif isfield(preset,'airpuff_dur')
    % oldest preset format (single airpuff pulse, no train at all) --
    % convert to an equivalent 1-pulse train
    set(handles.airpuff_pulse_len,'String',preset.airpuff_dur);
    set(handles.airpuff_n_pulses,'String','1');
    set(handles.airpuff_total_time,'String',preset.airpuff_dur);
end
set(handles.stim_dur,'String',preset.stim_dur);
set(handles.iti_min,'String',preset.iti_min);
set(handles.iti_max,'String',preset.iti_max);
set(handles.iti_initial,'String',preset.iti_initial);
set(handles.n_trials,'String',preset.n_trials);
session.exp.daqChannelMap = preset.daqChannelMap;
populateDaqChannelTable(handles);

updateAudioControlsEnable(handles);
updateAirpuffControlsEnable(handles);

% restore the Window 2 trial block, if this preset was saved with one
if isfield(preset,'trials') && istable(preset.trials) && height(preset.trials)>0
    session.exp.trials = preset.trials;
    session.exp.n_trials = height(preset.trials);
    set(handles.n_trials,'String',num2str(session.exp.n_trials));
    populateBlockTable(handles);
    updateBlockPreview(handles);
    set(handles.run_setup_ok,'Enable','on');
    blockMsg = 'Its saved trial block (Window 2) was restored and is ready to run.';
else
    if isfield(session.exp,'trials')
        session.exp = rmfield(session.exp,'trials'); % this preset didn't come with a block -- don't leave a stale one showing
    end
    updateBlockPreview(handles); % shows the "generate a block first" placeholder
    set(handles.run_setup_ok,'Enable','off');
    blockMsg = 'This preset was saved without a trial block -- click "Generate Block" (Window 2) to build one.';
end

msgbox(sprintf('Loaded preset "%s". %s',name,blockMsg),'Preset loaded');

% --- Executes on button press in delete_preset.
function delete_preset_Callback(hObject, eventdata, handles)
names = get(handles.preset_list,'String');
name = names{get(handles.preset_list,'Value')};
if strcmp(name,'(no presets saved yet)')
    return
end
answer = questdlg(sprintf('Delete preset "%s"? This cannot be undone.',name), ...
    'Delete preset','Yes','No','No');
if strcmp(answer,'Yes')
    delete(fullfile(presetDir(),[name '.mat']));
    refreshPresetList(handles);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% DAQ CHANNELS %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Full channel inventory for our NI PCIe-6321, per its specifications
% (NI doc 374461C-01): 16 single-ended analog inputs (AI0-AI15, or 8
% differential pairs), 2 analog outputs (AO0-AO1, +-10V only), 24 digital
% I/O lines across 3 ports (P0.<0..7>, P1.<0..7>/PFI<0..7>,
% P2.<0..7>/PFI<8..15>), and 4 general-purpose counter/timers (ctr0-
% ctr3, all real on this device). Every AI/AO/digital row can be
% assigned a role (Reward, Lick, Audio, Airpuff, TTL Sync, TTL In, or
% Unused); the 24 digital lines can also have their Direction
% (Input/Output) changed. Assigning an exclusive role (Reward/Lick/
% Audio/Airpuff/TTL Sync) to a channel automatically vacates whichever
% other channel used to hold that role in the same direction, so there's
% always exactly one holder. Ball (AI0-AI7) and Photometry (ctr0-ctr3)
% rows are locked -- they're multi-channel systems owned by
% BallInitialize.m / LEDInitialize.m.
%
% NOTE: unlike a device with a 32-line Port 0, this device's Port 0 only
% has 8 lines (P0.<0..7>), so the default wiring below is spread across
% all three 8-line ports (P0/P1/P2) rather than crammed onto P0 alone.
% Port 0 vs Port 1/2 makes no functional difference here -- nothing in
% this task uses Port 0's hardware-timed bulk-waveform capability, only
% simple static digital I/O, which P1/P2 (PFI) support equally well.

% builds the full channel inventory above, with reward/lick/airpuff/
% audio/TTL-sync/spare-TTL-in/ball/photometry defaulted to a layout that
% fits this device's actual pin budget; everything else defaults to
% Unused and is free to assign.
function map = buildDefaultChannelMap()
map = struct('key',{},'label',{},'port',{},'type',{},'direction',{},'assignment',{},'amplitude',{},'editable',{});

% ---- Analog Input: AI0-AI15 (16 single-ended channels) ----
% AI0-AI7 are the ball treadmill's 2 optical mice (magnitude+sign per
% axis) -- fixed/owned by BallInitialize.m
for n = 0:15
    if n <= 7
        map(end+1) = channelRow(sprintf('ai%d',n),sprintf('AI %d',n),sprintf('ai%d',n),'analog','in','Ball',NaN,false); %#ok<AGROW>
    else
        map(end+1) = channelRow(sprintf('ai%d',n),sprintf('AI %d',n),sprintf('ai%d',n),'analog','in','Unused',NaN,true); %#ok<AGROW>
    end
end

% ---- Analog Output: AO0-AO1 (2 channels, +-10V only) ----
% none used by default; assign one to Audio/Airpuff if you want an
% analog-triggered stimulus (Amplitude sets the "on" voltage)
for n = 0:1
    map(end+1) = channelRow(sprintf('ao%d',n),sprintf('AO %d',n),sprintf('ao%d',n),'analog','out','Unused',5,true); %#ok<AGROW>
end

% ---- Digital I/O Port 0: P0.0-P0.7 (8 lines) ----
% reward + lick + airpuff live here
for n = 0:7
    map(end+1) = channelRow(sprintf('p0_%d',n),sprintf('P0.%d',n),sprintf('Port0/Line%d',n),'digital','in','Unused',NaN,true); %#ok<AGROW>
end
p0StartIdx = numel(map) - 8; % index (0-based offset) of P0.0 within map
p0Line      = [0,       1,       2,      3,       4       ];
p0Direction = {'out',   'in',    'in',   'out',   'in'    };
p0Assign    = {'Reward','Reward','Lick', 'Airpuff','Airpuff'};
for i = 1:numel(p0Line)
    idx = p0StartIdx + p0Line(i) + 1;
    map(idx).direction = p0Direction{i};
    map(idx).assignment = p0Assign{i};
end

% ---- Digital I/O Port 1: P1.0-P1.7 / PFI0-PFI7 (8 lines) ----
% audio lives here
map(end+1) = channelRow('p1_0','P1.0 (PFI 0)','Port1/Line0','digital','out','Audio',NaN,true); %#ok<AGROW>
map(end+1) = channelRow('p1_1','P1.1 (PFI 1)','Port1/Line1','digital','in','Audio',NaN,true); %#ok<AGROW>
for n = 2:7
    map(end+1) = channelRow(sprintf('p1_%d',n),sprintf('P1.%d (PFI %d)',n,n),sprintf('Port1/Line%d',n),'digital','in','Unused',NaN,true); %#ok<AGROW>
end

% ---- Digital I/O Port 2: P2.0-P2.7 / PFI8-PFI15 (8 lines) ----
% TTL sync + spare TTL ins live here
map(end+1) = channelRow('p2_0','P2.0 (PFI 8)','Port2/Line0','digital','out','TTL Sync',NaN,true); %#ok<AGROW>
map(end+1) = channelRow('p2_1','P2.1 (PFI 9)','Port2/Line1','digital','in','TTL Sync',NaN,true); %#ok<AGROW>
for n = 2:6 % 5 spare TTL In lines
    map(end+1) = channelRow(sprintf('p2_%d',n),sprintf('P2.%d (PFI %d)',n,n+8),sprintf('Port2/Line%d',n),'digital','in','TTL In',NaN,true); %#ok<AGROW>
end
map(end+1) = channelRow('p2_7','P2.7 (PFI 15)','Port2/Line7','digital','in','Unused',NaN,true); %#ok<AGROW>

% ---- General-purpose counter/timers: ctr0-ctr3 (all 4 real on this device) ----
% used by LEDInitialize.m for photometry excitation LEDs -- fixed/owned
% by that script (not exposed in this GUI's Task Setup, but still listed
% here and left reserved), not reassignable from this table
map(end+1) = channelRow('ctr0','Ctr 0','ctr0','counter','out','Photometry',NaN,false);
map(end+1) = channelRow('ctr1','Ctr 1','ctr1','counter','out','Photometry',NaN,false);
map(end+1) = channelRow('ctr2','Ctr 2','ctr2','counter','out','Photometry',NaN,false);
map(end+1) = channelRow('ctr3','Ctr 3','ctr3','counter','out','Photometry',NaN,false);

function row = channelRow(key,label,port,type,direction,assignment,amplitude,editable)
row.key = key; row.label = label; row.port = port; row.type = type;
row.direction = direction; row.assignment = assignment; row.amplitude = amplitude;
row.editable = editable;

% helper: push session.exp.daqChannelMap into the uitable
function populateDaqChannelTable(handles)
global session
map = session.exp.daqChannelMap;
data = cell(numel(map),5);
for i = 1:numel(map)
    data{i,1} = map(i).label;
    data{i,2} = map(i).type;
    if strcmp(map(i).direction,'out')
        data{i,3} = 'Output';
    else
        data{i,3} = 'Input';
    end
    data{i,4} = map(i).assignment;
    data{i,5} = map(i).amplitude;
end
set(handles.daq_channel_table,'Data',data);

% --- Executes when entered data in editable cell(s) in daq_channel_table.
function daq_channel_table_CellEditCallback(hObject, eventdata, handles)
global session
map = session.exp.daqChannelMap;
row = eventdata.Indices(1);
col = eventdata.Indices(2);

if ~map(row).editable
    populateDaqChannelTable(handles); % discard the edit
    warndlg(sprintf('"%s" is a fixed system channel (owned by BallInitialize.m / LEDInitialize.m) and can''t be edited here.', map(row).label), 'Channel locked');
    return
end

colNames = {'Channel','Type','Direction','Assignment','Amplitude (V)'};
switch colNames{col}
    case 'Direction'
        if ~strcmp(map(row).type,'digital')
            populateDaqChannelTable(handles); % discard the edit
            warndlg('Only digital (Port 0/1/2) channels can change direction -- analog and counter channels have a fixed direction.','Invalid edit');
            return
        end
        if strcmp(eventdata.NewData,'Output')
            map(row).direction = 'out';
        else
            map(row).direction = 'in';
        end
        map = enforceExclusiveAssignment(map,row);
    case 'Assignment'
        newAssign = eventdata.NewData;
        if any(strcmp(newAssign,{'Ball','Photometry'}))
            populateDaqChannelTable(handles); % discard the edit
            warndlg('Ball and Photometry are fixed system assignments (owned by BallInitialize.m / LEDInitialize.m) and can''t be assigned to another channel from this table.','Invalid assignment');
            return
        end
        map(row).assignment = newAssign;
        map = enforceExclusiveAssignment(map,row);
    case 'Amplitude (V)'
        map(row).amplitude = eventdata.NewData;
end
session.exp.daqChannelMap = map;
populateDaqChannelTable(handles);

% helper: Reward/Lick/Audio/Airpuff/TTL Sync must have at most one holder
% per direction -- if this row now holds one of those roles, vacate
% (reset to Unused) whichever OTHER channel used to hold that same
% role+direction combo, so there's always exactly one holder
function map = enforceExclusiveAssignment(map,row)
exclusiveRoles = {'Reward','Lick','Audio','Airpuff','TTL Sync'};
if any(strcmp(map(row).assignment,exclusiveRoles))
    for k = 1:numel(map)
        if k~=row && strcmp(map(k).assignment,map(row).assignment) && strcmp(map(k).direction,map(row).direction)
            map(k).assignment = 'Unused';
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% TASK SETUP %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in audio_yes.
function audio_yes_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of audio_yes
updateAudioControlsEnable(handles);

% helper: session.exp.tone must always be a non-empty struct before any
% of the tone_*_Callback functions below dot-index into it. It can end
% up as something else (e.g. 0) if a preset saved under an older version
% of this script is loaded, or from other stale/leftover global state --
% repair it back to a single default tone rather than crashing.
function ensureToneStruct()
global session
if ~isstruct(session.exp.tone) || isempty(fieldnames(session.exp.tone))
    session.exp.tone = struct();
    session.exp.tone.tone1.freq = 7;
    session.exp.tone.tone1.vol = 1;
end

function tone_n_Callback(hObject, eventdata, handles)
global session
ensureToneStruct();
tone_n = round(str2double(get(handles.tone_n,'String')));
if isnan(tone_n) || tone_n<1
    tone_n = 1; % never let this drop to 0/invalid -- that would delete every configured tone below
end
set(hObject,'String',num2str(tone_n));
tone_str = cell(tone_n,1);
for i = 1:tone_n
    tone_str{i} = ['tone' num2str(i)];
    if ~isfield(session.exp.tone,tone_str{i})
        session.exp.tone.(tone_str{i}).freq = 7;
        session.exp.tone.(tone_str{i}).vol = 1;
    end
end
tone_fields = fieldnames(session.exp.tone);
% remove unnecessary fields
tone_fields_rm = setdiff(tone_fields,tone_str);
if ~isempty(tone_fields_rm)
    for i = 1:numel(tone_fields_rm)
        session.exp.tone = rmfield(session.exp.tone,tone_fields_rm{i});
    end
end
set(handles.tone_list,'String',tone_str)

% --- Executes on selection change in tone_list.
function tone_list_Callback(hObject, eventdata, handles)
global session
ensureToneStruct();
% update tone list if necessary
tone_n = round(str2double(get(handles.tone_n,'String')));
if isnan(tone_n) || tone_n<1
    tone_n = 1;
end
tone_str = cell(tone_n,1);
for i = 1:tone_n
    tone_str{i} = ['tone' num2str(i)];
    if ~isfield(session.exp.tone,tone_str{i})
        session.exp.tone.(tone_str{i}).freq = -1;
        session.exp.tone.(tone_str{i}).vol = [-1];
    end
end
set(handles.tone_list,'String',tone_str)
set(handles.tone_freq,'String',num2str(session.exp.tone.(['tone' num2str(get(hObject,'Value'))]).freq));
set(handles.tone_vol,'String',strjoin(cellstr(num2str(session.exp.tone.(['tone' num2str(get(hObject,'Value'))]).vol'))',','));

function tone_freq_Callback(hObject, eventdata, handles)
global session
ensureToneStruct();
thisTone = ['tone' num2str(get(handles.tone_list,'Value'))];
if ~isfield(session.exp.tone,thisTone)
    session.exp.tone.(thisTone).vol = 1;
end
session.exp.tone.(thisTone).freq = str2double(get(handles.tone_freq,'String'));

function tone_vol_Callback(hObject, eventdata, handles)
global session
ensureToneStruct();
thisTone = ['tone' num2str(get(handles.tone_list,'Value'))];
if ~isfield(session.exp.tone,thisTone)
    session.exp.tone.(thisTone).freq = 7;
end
session.exp.tone.(thisTone).vol = str2num(get(handles.tone_vol,'String'));

function audio_dur_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of audio_dur as text
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String','2')
end

% --- Executes on button press in airpuff_yes.
function airpuff_yes_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of airpuff_yes
updateAirpuffControlsEnable(handles);

function airpuff_pulse_len_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of airpuff_pulse_len as text
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String','0.05')
end

function airpuff_n_pulses_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of airpuff_n_pulses as text
val = round(str2double(get(hObject,'String')));
if isnan(val) || val<1
    val = 1;
end
set(hObject,'String',num2str(val));

function airpuff_total_time_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of airpuff_total_time as text
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String','0.05')
end

% --- Executes on button press in paired_yes.
function paired_yes_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of paired_yes
% paired trials need both the audio (tone) settings and the airpuff
% parameters, so toggling this re-evaluates whether those controls should
% be enabled even if audio_yes / airpuff_yes are unchecked on their own
updateAudioControlsEnable(handles);
updateAirpuffControlsEnable(handles);

function stim_dur_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of stim_dur as text

% helper: enable/disable the tone (audio) controls based on whether audio
% or paired trials are requested
function updateAudioControlsEnable(handles)
if get(handles.audio_yes,'Value')==1 || get(handles.paired_yes,'Value')==1
    onoff = 'on';
else
    onoff = 'off';
end
set(handles.tone_n,'Enable',onoff)
set(handles.audio_dur,'Enable',onoff)
set(handles.tone_list,'Enable',onoff)
set(handles.tone_freq,'Enable',onoff)
set(handles.tone_vol,'Enable',onoff)

% helper: enable/disable the airpuff pulse-train controls based on
% whether airpuff or paired trials are requested
function updateAirpuffControlsEnable(handles)
if get(handles.airpuff_yes,'Value')==1 || get(handles.paired_yes,'Value')==1
    onoff = 'on';
else
    onoff = 'off';
end
set(handles.airpuff_pulse_len,'Enable',onoff)
set(handles.airpuff_n_pulses,'Enable',onoff)
set(handles.airpuff_total_time,'Enable',onoff)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% RUNTIME %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function iti_min_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String'))<0
    set(hObject,'String','0')
end
if str2double(get(hObject,'String'))>str2double(get(handles.iti_max,'String'))
    set(hObject,'String',get(handles.iti_max,'String'))
end

function iti_max_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String')) < str2double(get(handles.iti_min,'String'))
    set(hObject,'String',(get(handles.iti_min,'String')))
end
if str2double(get(hObject,'String'))<0
    set(hObject,'String','0')
end
if str2double(get(hObject,'String'))<str2double(get(handles.iti_min,'String'))
    set(hObject,'String',get(handles.iti_min,'String'))
end

function iti_initial_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of iti_initial as text


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% TRIAL BLOCK %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section lets you set the number of trials in the block (300+ is
% fine), auto-generate a randomly-ordered audio/airpuff/paired assignment
% for the whole block (10% audio-only, 10% airpuff-only, 80% paired --
% see generatePairedStimTrialOrder), hand-edit individual trials in the
% table, and see the whole block colored (red=audio, blue=airpuff,
% purple=paired) before you ever touch the DAQ hardware via "Setup OK".

function n_trials_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of n_trials as text
val = round(str2double(get(hObject,'String')));
if isnan(val) || val<1
    val = 1;
end
set(hObject,'String',num2str(val));

% --- Executes on button press in generate_block.
function generate_block_Callback(hObject, eventdata, handles)
global session

session.exp.audio_yes = get(handles.audio_yes,'Value');
session.exp.airpuff_yes = get(handles.airpuff_yes,'Value');
session.exp.paired_yes = get(handles.paired_yes,'Value');
if session.exp.audio_yes==0 && session.exp.airpuff_yes==0 && session.exp.paired_yes==0
    errordlg('Select at least one stimulation type (audio, airpuff, or paired).','Cannot generate block')
    return
end
% NOTE: session.exp.tone is intentionally left alone here even when
% Audio/Paired are unchecked -- generatePairedStimTrialOrder only reads
% it for modalities that are actually enabled, so there's no need to
% (and no longer any code that used to) zero it out. Doing so previously
% meant re-checking Audio/Paired after generating an airpuff-only block
% would permanently break tone configuration with a "configure at least
% one tone" error, since nothing ever rebuilt it afterward.

nTrials = round(str2double(get(handles.n_trials,'String')));
if isnan(nTrials) || nTrials<1
    errordlg('Enter a valid number of trials (1 or more).','Cannot generate block')
    return
end
set(handles.n_trials,'String',num2str(nTrials));
session.exp.n_trials = nTrials;

session.exp.iti_interval = [str2double(get(handles.iti_min,'String')),...
    str2double(get(handles.iti_max,'String'))];
session.exp.iti_initial = str2double(get(handles.iti_initial,'String'));

try
    generatePairedStimTrialOrder; % builds session.exp.trials.{modality,frequency,level}
catch err
    errordlg(err.message,'Cannot generate block')
    return
end
% add in ITI
if range(session.exp.iti_interval)>0
    session.exp.trials.iti = transpose(randsample(session.exp.iti_interval(1):session.exp.iti_interval(2),session.exp.n_trials,1));
else
    session.exp.trials.iti = repmat(session.exp.iti_interval(1),session.exp.n_trials,1);
end
session.exp.trials.iti(1) = session.exp.iti_initial;

populateBlockTable(handles);
updateBlockPreview(handles);
set(handles.run_setup_ok,'Enable','on');

% --- Executes when entered data in editable cell(s) in block_table.
function block_table_CellEditCallback(hObject, eventdata, handles)
global session
row = eventdata.Indices(1);
col = eventdata.Indices(2);
switch col
    case 2 % modality
        switch eventdata.NewData
            case 'audio'
                newModality = 0;
            case 'airpuff'
                newModality = 1;
            case 'paired'
                newModality = 2;
            otherwise
                newModality = session.exp.trials.modality(row); % unrecognized -> leave unchanged
        end
        session.exp.trials.modality(row) = newModality;
        if newModality == 1 % airpuff-only: no tone needed
            session.exp.trials.frequency(row) = NaN;
            session.exp.trials.level(row) = NaN;
        elseif isnan(session.exp.trials.frequency(row))
            % switching a trial to audio/paired that didn't have a tone yet
            if ~isstruct(session.exp.tone) || isempty(fieldnames(session.exp.tone))
                errordlg('Configure at least one tone in the Audio panel first.','Cannot assign audio/paired')
                session.exp.trials.modality(row) = 1; % revert to airpuff
            else
                toneFields = fieldnames(session.exp.tone);
                session.exp.trials.frequency(row) = session.exp.tone.(toneFields{1}).freq;
                session.exp.trials.level(row) = session.exp.tone.(toneFields{1}).vol(1);
            end
        end
    case 3 % frequency
        session.exp.trials.frequency(row) = eventdata.NewData;
    case 4 % level
        session.exp.trials.level(row) = eventdata.NewData;
    case 5 % iti
        session.exp.trials.iti(row) = eventdata.NewData;
end
populateBlockTable(handles); % refresh in case freq/level got auto-filled above
updateBlockPreview(handles);

% helper: push session.exp.trials into the uitable
function populateBlockTable(handles)
global session
n = session.exp.n_trials;
modalityNames = {'audio','airpuff','paired'};
data = cell(n,5);
for t = 1:n
    data{t,1} = t;
    data{t,2} = modalityNames{session.exp.trials.modality(t)+1};
    data{t,3} = session.exp.trials.frequency(t);
    data{t,4} = session.exp.trials.level(t);
    data{t,5} = session.exp.trials.iti(t);
end
set(handles.block_table,'Data',data);

% helper: draw the whole block as a grid of colored cells
% (red = audio, blue = airpuff, purple = paired) for visual confirmation
function updateBlockPreview(handles)
global session
ax = handles.blockPreviewAxes;
cla(ax)
if ~isfield(session.exp,'trials') || isempty(session.exp.trials)
    text(0.5,0.5,{'No block generated yet.','Set "# trials" above and click "Generate Block".'}, ...
        'Parent',ax,'Units','normalized','HorizontalAlignment','center')
    set(ax,'XTick',[],'YTick',[],'XLim',[0 1],'YLim',[0 1])
    return
end
modality = session.exp.trials.modality;
N = numel(modality);
colorMap = [0.85 0.15 0.15; 0.15 0.35 0.85; 0.55 0.15 0.65]; % audio=red, airpuff=blue, paired=purple
nCols = min(N,30);
nRows = ceil(N/nCols);
img = ones(nRows,nCols,3); % unused cells (padding) stay white
cellRow = zeros(N,1);
cellCol = zeros(N,1);
for t = 1:N
    r = ceil(t/nCols);
    c = t - (r-1)*nCols;
    img(r,c,:) = colorMap(modality(t)+1,:);
    cellRow(t) = r;
    cellCol(t) = c;
end
image(ax,img);
axis(ax,'image')
hold(ax,'on')
% label every cell with its trial number, in white (readable against all
% 3 fill colors -- red/blue/purple are all dark/saturated enough)
fontSize = max(4,min(8,floor(220/nCols)));
for t = 1:N
    text(ax,cellCol(t),cellRow(t),num2str(t),'HorizontalAlignment','center', ...
        'VerticalAlignment','middle','Color','white','FontSize',fontSize);
end
set(ax,'XTick',0.5:1:(nCols+0.5),'YTick',0.5:1:(nRows+0.5),'XTickLabel',[],'YTickLabel',[], ...
    'GridColor',[0.25 0.25 0.25],'GridAlpha',0.6,'GridLineStyle','-')
grid(ax,'on')
title(ax,sprintf('%d trials (%d audio, %d airpuff, %d paired)', N, ...
    sum(modality==0), sum(modality==1), sum(modality==2)))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% SETUP FUNCTIONS %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function generatePairedStimTrialOrder
% columns: modality (0=audio, 1=airpuff, 2=paired), freq, vol level
% (airpuff-only trials get freq/level = NaN, since there's no tone)
%
% Block composition is fixed at 10% audio-only, 10% airpuff-only, 80%
% paired -- paired is the majority condition, audio/airpuff are rare
% single-modality probe trials. If one of the three is unchecked in Task
% Setup, its share is dropped and the remaining shares are renormalized
% (e.g. audio+airpuff only, no paired -> 50/50). Trial ORDER is still
% fully randomized (scrambled below), only the overall counts are fixed
% to hit these target percentages.
global session
rng shuffle

modalityOrder = [0 1 2]; % 0 = audio, 1 = airpuff, 2 = paired
targetShare   = [0.10 0.10 0.80];
enabled = [session.exp.audio_yes==1, session.exp.airpuff_yes==1, session.exp.paired_yes==1];
if ~any(enabled)
    error('Select at least one stimulation type (audio, airpuff, or paired).')
end
modalities = modalityOrder(enabled);
share = targetShare(enabled);
share = share / sum(share); % renormalize to 100% over whichever types are enabled

nEach = round(session.exp.n_trials * share);
nEach(end) = session.exp.n_trials - sum(nEach(1:end-1)); % last enabled type absorbs the rounding remainder

trialmat = [];
for m = 1:numel(modalities)
    thisModality = modalities(m);
    n = nEach(m);
    if thisModality == 1 % airpuff-only: no tone freq/level needed
        thismat = [repmat(thisModality,n,1), nan(n,1), nan(n,1)];
    else % audio or paired: assign tone freq/level from configured tone list
        thismat = [repmat(thisModality,n,1), assignToneParams(n)];
    end
    trialmat = [trialmat; thismat];
end

% scramble trial order (many times, as in SalientStimuli.m) -- this is
% what actually gives each trial a random modality assignment while
% still hitting the exact target counts/percentages above
for i = 1:500
    idx = randperm(size(trialmat,1));
    trialmat = trialmat(idx,:);
end

session.exp.trials = table(transpose(1:session.exp.n_trials),'VariableNames',{'trialNum'});
session.exp.trials.modality = trialmat(:,1);
session.exp.trials.frequency = trialmat(:,2);
session.exp.trials.level = trialmat(:,3);


function tonemat = assignToneParams(n)
% assigns [frequency level] pairs to n trials, evenly split across all
% configured tones and, within each tone, evenly split across its volume
% levels (ported from generateSalientStimTrialOrder in SalientStimuli.m)
global session
if ~isstruct(session.exp.tone) || isempty(fieldnames(session.exp.tone))
    error('Configure at least one tone before running audio or paired trials.')
end
tonemat = ones(n,2);
toneFields = fieldnames(session.exp.tone);
nTones = numel(toneFields);
ni = round(linspace(0,n,nTones+1));
for i = 1:nTones
    theseTrials = (ni(i)+1):ni(i+1);
    tonemat(theseTrials,1) = session.exp.tone.(toneFields{i}).freq;
    vol = session.exp.tone.(toneFields{i}).vol;
    mi = round(linspace(0,numel(theseTrials),numel(vol)+1));
    for j = 1:numel(vol)
        tonemat(theseTrials(mi(j)+1:mi(j+1)),2) = vol(j);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% RUN %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in run_setup_ok.
function run_setup_ok_Callback(hObject, eventdata, handles)
global session
if ~isfield(session.exp,'trials') || isempty(session.exp.trials)
    errordlg('Generate the trial block first.','Cannot start setup')
    return
end
if session.exp.n_trials ~= round(str2double(get(handles.n_trials,'String')))
    errordlg('The trial count changed since the block was generated -- click "Generate Block" again.','Cannot start setup')
    return
end
% validate the airpuff pulse train and the audio tone duration both fit
% within the trial/stim window, BEFORE disabling anything below, so a
% failed check here doesn't leave the GUI half-locked
stimDur = str2double(get(handles.stim_dur,'String'));

% Airpuff is controlled by 3 user inputs -- pulse length, # of pulses,
% and total time -- rather than an explicit inter-pulse interval (IPI).
% IPI is derived so exactly N pulses of the given length fit evenly
% within the given total time: IPI = (total - N*len) / (N-1).
airpuffPulseLen = str2double(get(handles.airpuff_pulse_len,'String'));
airpuffNPulses = round(str2double(get(handles.airpuff_n_pulses,'String')));
airpuffTotal = str2double(get(handles.airpuff_total_time,'String'));
minTotal = airpuffNPulses*airpuffPulseLen; % shortest total time that fits N pulses back-to-back with no gap
if airpuffTotal < minTotal
    errordlg(sprintf(['Total time (%.3gs) is too short to fit %d pulses of %.3gs each -- ' ...
        'that needs at least %.3gs even with zero gap between pulses. Increase Total time, ' ...
        'or reduce the pulse length/count.'], ...
        airpuffTotal, airpuffNPulses, airpuffPulseLen, minTotal), 'Cannot start setup')
    return
end
if airpuffNPulses > 1
    airpuffIPI = (airpuffTotal - minTotal) / (airpuffNPulses-1);
else
    airpuffIPI = 0; % a single pulse has no gap to compute
end
if airpuffTotal > stimDur
    errordlg(sprintf('Airpuff total time (%.3gs) exceeds the trial/stim duration (%.3gs). Reduce the total time, or increase the trial/stim duration.', ...
        airpuffTotal, stimDur), 'Cannot start setup')
    return
end
audioDur = str2double(get(handles.audio_dur,'String'));
if audioDur > stimDur
    errordlg(sprintf('Audio tone duration (%.3gs) exceeds the trial/stim duration (%.3gs). Reduce the tone duration, or increase the trial/stim duration.', ...
        audioDur, stimDur), 'Cannot start setup')
    return
end
warning('off','daq:Session:onDemandOnlyChannelsAdded')
% disable a bunch of things from further editing
set(handles.save_path_button,'Enable','off')
set(handles.save_path,'Enable','off')
set(handles.filename_prefix,'Enable','off')
set(handles.preset_list,'Enable','off')
set(handles.load_preset,'Enable','off')
set(handles.save_preset,'Enable','off')
set(handles.delete_preset,'Enable','off')
set(handles.audio_yes,'Enable','off')
set(handles.tone_n,'Enable','off')
set(handles.audio_dur,'Enable','off')
set(handles.tone_list,'Enable','off')
set(handles.tone_freq,'Enable','off')
set(handles.tone_vol,'Enable','off')
set(handles.airpuff_yes,'Enable','off')
set(handles.airpuff_pulse_len,'Enable','off')
set(handles.airpuff_n_pulses,'Enable','off')
set(handles.airpuff_total_time,'Enable','off')
set(handles.paired_yes,'Enable','off')
set(handles.stim_dur,'Enable','off')
set(handles.iti_min,'Enable','off')
set(handles.iti_max,'Enable','off')
set(handles.iti_initial,'Enable','off')
set(handles.n_trials,'Enable','off')
set(handles.generate_block,'Enable','off')
set(handles.block_table,'ColumnEditable',false(1,5));
set(handles.daq_channel_table,'ColumnEditable',false(1,5));
try
    set(handles.block_table,'Enable','off');
    set(handles.daq_channel_table,'Enable','off');
catch
    % older MATLAB uitable implementations may not support 'Enable';
    % ColumnEditable=false above already locks the data from editing
end
set(handles.run_setup_ok,'Enable','off')

%%%%% saving out the data
% the mouse prefix (replace spaces with underscore)
session.mouse = get(handles.filename_prefix,'String');
session.mouse = strjoin(strsplit(session.mouse,' '),'_');
if strncmp(session.mouse(end),'_',1)
    session.mouse = session.mouse(1:end-1);
end
% the filename (and also update that field)
filename = [session.mouse '_' datestr(clock,'YYYY.mm.dd_HH.MM.ss')];
session.dataFilename = fullfile(get(handles.save_path,'String'),filename);
%%%%% initialize some session variables
session.temp.refreshDisplay=3;
session.exp.delayCond = 0;
session.exp.salient_stim = 1; % reuse the SalientStimuli real-time plotting hook
% (stimDur/airpuffPulseLen/airpuffNPulses/airpuffTotal/audioDur were
% already read from the GUI, and airpuffIPI already derived from them,
% before anything got disabled above)
session.exp.stim_dur = stimDur;
session.exp.airpuff_pulse_len = airpuffPulseLen;
session.exp.airpuff_ipi = airpuffIPI; % derived from pulse length/# of pulses/total time
session.exp.airpuff_n_pulses = airpuffNPulses;
session.exp.airpuff_dur = airpuffTotal; % total pulse-train time (as entered)
session.exp.audio_dur = audioDur;

%%%%% initialize other things
daqSessionInitialize;
BallInitialize;
% PairedStimuli_Initialize creates the reward/lick/stimulus/TTL-sync/
% spare-TTL-in channels dynamically from session.exp.daqChannelMap (the
% DAQ Channels table), so TTLSyncInitialize.m is NOT called here -- its
% job is already covered by that table.
try
    PairedStimuli_Initialize;
catch err
    errordlg(err.message,'DAQ channel setup failed')
    set(handles.run_setup_ok,'Enable','on')
    return
end
%%%%% finalize setup
daqSessionInitializeDataBuffer(1); % initialize the data buffer for vis.
daqSessionInitializeOutputs; % gather the output channels and initialize

%%% enable start button
set(handles.run_start,'Enable','on')


% --- Executes on button press in run_start.
function run_start_Callback(hObject, eventdata, handles)
global session % our global variable to store everything
set(handles.run_start,'Enable','off')
set(handles.run_stop,'Enable','on')
session.starttime = datestr(clock);
session.temp.rewTimer = tic;
disp('*******************')
trialUpdate % update task state variables and display
daqSessionRecord; % start the session

% --- Executes on button press in run_stop.
function run_stop_Callback(hObject, eventdata, handles)
global session % our global variable to store everything
set(handles.run_stop,'Enable','off') % turn off the stop button
daqSessionClose; % close data acquisition session
% see if you want to save out data
answer = questdlg('Save acquired data?', ...
	'Save acquired data?', ...
	'Yes','No','Yes');
% Handle response
switch answer
    case 'Yes'
        daqSessionSave; % save out the full data from the session
    case 'No'
        daqSessionDeleteBackup; % delete the backup file logging the data
end

% close both GUI windows
if ishandle(handles.figure1)
    close(handles.figure1)
end
if ishandle(handles.figure2)
    close(handles.figure2)
end
clear global % clear global variables

% see if you want to run another experiment
answer = questdlg('Start another session?', ...
	'Start another session?', ...
	'Yes','No','Yes');
% Handle response
switch answer
    case 'Yes'
        run('PairedStimuli');
    case 'No'
end

function trialUpdate
    global session

    % update some variables
    session.temp.ITI = session.exp.trials.iti(session.temp.currentTrial);
    session.temp.currentStim = session.exp.trials.modality(session.temp.currentTrial);
    session.temp.currentFreq = session.exp.trials.frequency(session.temp.currentTrial);
    session.temp.currentLevel = session.exp.trials.level(session.temp.currentTrial);

    % display trial information
    session.temp.stimLabel = {'audio','airpuff','paired'};
    disp(['trial #' num2str(session.temp.currentTrial) ' in ' num2str(session.temp.ITI) 's:'])
    str1 = session.temp.stimLabel{session.temp.currentStim+1};
    if session.temp.currentStim==1 % airpuff-only: no tone to report
        str2 = ' ';
        str3 = sprintf(' %dx%.3gs pulses, %.3gs IPI, %.3gs total', ...
            session.exp.airpuff_n_pulses, session.exp.airpuff_pulse_len, session.exp.airpuff_ipi, session.exp.airpuff_dur);
    else
        str2 = [' ' num2str(session.temp.currentFreq) 'kHz'];
        str3 = [' level ' num2str(session.temp.currentLevel)];
    end
    disp([str1 str2 str3])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% GUI LAYOUT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This GUI is built programmatically (no .fig file). The layout below
% creates the same controls that a GUIDE .fig would normally supply, and
% wires each one to the callback functions defined above. Every panel and
% control uses 'Units','normalized' (relative to its parent), so the
% whole GUI reflows and rescales smoothly when the figure window is
% resized -- no fixed pixel positions.

function handles = PairedStimuli_LayoutFcn()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% WINDOW 1: SETUP %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig = figure('Units','pixels','Position',[50 60 1150 850], ...
    'Name','PairedStimuli - Setup','MenuBar','none','ToolBar','none', ...
    'NumberTitle','off','Resize','on','Tag','figure1');
handles.figure1 = fig;

%%%%% Save Output panel
pSave = uipanel('Parent',fig,'Title','Save Output','Units','normalized','Position',[0.02 0.900 0.96 0.080]);
uicontrol('Parent',pSave,'Style','text','String','Save path:','Units','normalized','Position',[0.01 0.15 0.08 0.7],'HorizontalAlignment','left');
handles.save_path = uicontrol('Parent',pSave,'Style','edit','String',pwd,'Units','normalized','Position',[0.10 0.15 0.45 0.7],'BackgroundColor','white');
set(handles.save_path,'Callback',@(h,e) save_path_Callback(h,e,guidata(h)));
handles.save_path_button = uicontrol('Parent',pSave,'Style','pushbutton','String','Browse...','Units','normalized','Position',[0.56 0.15 0.09 0.7]);
set(handles.save_path_button,'Callback',@(h,e) save_path_button_Callback(h,e,guidata(h)));
uicontrol('Parent',pSave,'Style','text','String','Filename prefix:','Units','normalized','Position',[0.67 0.15 0.11 0.7],'HorizontalAlignment','left');
handles.filename_prefix = uicontrol('Parent',pSave,'Style','edit','String','mouse','Units','normalized','Position',[0.79 0.15 0.19 0.7],'BackgroundColor','white');
set(handles.filename_prefix,'Callback',@(h,e) filename_prefix_Callback(h,e,guidata(h)));

%%%%% Presets panel (save/load Task Setup + Runtime + DAQ Channels config)
pPreset = uipanel('Parent',fig,'Title','Presets','Units','normalized','Position',[0.02 0.825 0.96 0.065]);
uicontrol('Parent',pPreset,'Style','text','String','Preset:','Units','normalized','Position',[0.01 0.15 0.08 0.7],'HorizontalAlignment','left');
handles.preset_list = uicontrol('Parent',pPreset,'Style','popupmenu','String',{'(no presets saved yet)'},'Units','normalized','Position',[0.10 0.20 0.42 0.6],'BackgroundColor','white');
handles.load_preset = uicontrol('Parent',pPreset,'Style','pushbutton','String','Load','Units','normalized','Position',[0.54 0.15 0.13 0.7]);
set(handles.load_preset,'Callback',@(h,e) load_preset_Callback(h,e,guidata(h)));
handles.save_preset = uicontrol('Parent',pPreset,'Style','pushbutton','String','Save As...','Units','normalized','Position',[0.69 0.15 0.15 0.7]);
set(handles.save_preset,'Callback',@(h,e) save_preset_Callback(h,e,guidata(h)));
handles.delete_preset = uicontrol('Parent',pPreset,'Style','pushbutton','String','Delete','Units','normalized','Position',[0.86 0.15 0.12 0.7]);
set(handles.delete_preset,'Callback',@(h,e) delete_preset_Callback(h,e,guidata(h)));

%%%%% DAQ Channels panel (view + reconfigure every DAQ channel)
pDaq = uipanel('Parent',fig,'Title','DAQ Channels (NI PCIe-6321: 16 AI, 2 AO, 24 DIO, 4 counters)','Units','normalized','Position',[0.02 0.400 0.96 0.415]);
uicontrol('Parent',pDaq,'Style','text','Units','normalized','Position',[0.01 0.94 0.98 0.05],'HorizontalAlignment','left', ...
    'String','Every AI/AO/digital channel on this device (per its specifications). Edit Direction (digital only) and Assignment for any channel -- assigning an exclusive role (Reward/Lick/Audio/Airpuff/TTL Sync) auto-vacates its previous holder. Ball (AI0-7) and Photometry (Ctr0-3) rows are fixed system channels.');
handles.daq_channel_table = uitable('Parent',pDaq,'Units','normalized','Position',[0.01 0.02 0.98 0.91], ...
    'ColumnName',{'Channel','Type','Direction','Assignment','Amplitude (V)'}, ...
    'ColumnFormat',{'char','char',{'Input','Output'}, ...
        {'Unused','Reward','Lick','Audio','Airpuff','TTL Sync','TTL In','Ball','Photometry'},'numeric'}, ...
    'ColumnEditable',[false false true true true], ...
    'ColumnWidth',{280,70,80,110,100}, ...
    'RowName',[]);
set(handles.daq_channel_table,'CellEditCallback',@(h,e) daq_channel_table_CellEditCallback(h,e,guidata(h)));

%%%%% Task Setup panel
pTask = uipanel('Parent',fig,'Title','Task Setup','Units','normalized','Position',[0.02 0.140 0.96 0.240]);

% --- Audio sub-panel
pAudio = uipanel('Parent',pTask,'Title','Audio','Units','normalized','Position',[0.02 0.05 0.31 0.90]);
handles.audio_yes = uicontrol('Parent',pAudio,'Style','checkbox','String','Include audio trials','Value',1,'Units','normalized','Position',[0.05 0.85 0.9 0.12]);
set(handles.audio_yes,'Callback',@(h,e) audio_yes_Callback(h,e,guidata(h)));
uicontrol('Parent',pAudio,'Style','text','String','# of tones:','Units','normalized','Position',[0.05 0.68 0.5 0.10],'HorizontalAlignment','left');
handles.tone_n = uicontrol('Parent',pAudio,'Style','edit','String','1','Units','normalized','Position',[0.55 0.68 0.35 0.10],'BackgroundColor','white');
set(handles.tone_n,'Callback',@(h,e) tone_n_Callback(h,e,guidata(h)));
uicontrol('Parent',pAudio,'Style','text','String','Duration (s):','Units','normalized','Position',[0.05 0.58 0.5 0.08],'HorizontalAlignment','left');
handles.audio_dur = uicontrol('Parent',pAudio,'Style','edit','String','2','Units','normalized','Position',[0.55 0.58 0.35 0.08],'BackgroundColor','white');
set(handles.audio_dur,'Callback',@(h,e) audio_dur_Callback(h,e,guidata(h)));
uicontrol('Parent',pAudio,'Style','text','String','Tones:','Units','normalized','Position',[0.05 0.05 0.25 0.48],'HorizontalAlignment','left');
handles.tone_list = uicontrol('Parent',pAudio,'Style','listbox','String',{'tone1'},'Value',1,'Units','normalized','Position',[0.32 0.05 0.30 0.48],'BackgroundColor','white');
set(handles.tone_list,'Callback',@(h,e) tone_list_Callback(h,e,guidata(h)));
uicontrol('Parent',pAudio,'Style','text','String','Freq (kHz):','Units','normalized','Position',[0.65 0.44 0.32 0.10],'HorizontalAlignment','left');
handles.tone_freq = uicontrol('Parent',pAudio,'Style','edit','String','7','Units','normalized','Position',[0.65 0.32 0.32 0.10],'BackgroundColor','white');
set(handles.tone_freq,'Callback',@(h,e) tone_freq_Callback(h,e,guidata(h)));
uicontrol('Parent',pAudio,'Style','text','String','Vol level(s):','Units','normalized','Position',[0.65 0.20 0.32 0.10],'HorizontalAlignment','left');
handles.tone_vol = uicontrol('Parent',pAudio,'Style','edit','String','1','Units','normalized','Position',[0.65 0.08 0.32 0.10],'BackgroundColor','white');
set(handles.tone_vol,'Callback',@(h,e) tone_vol_Callback(h,e,guidata(h)));

% --- Airpuff sub-panel
pAirpuff = uipanel('Parent',pTask,'Title','Airpuff (whisker)','Units','normalized','Position',[0.35 0.05 0.31 0.90]);
handles.airpuff_yes = uicontrol('Parent',pAirpuff,'Style','checkbox','String','Include airpuff trials','Value',1,'Units','normalized','Position',[0.05 0.85 0.9 0.12]);
set(handles.airpuff_yes,'Callback',@(h,e) airpuff_yes_Callback(h,e,guidata(h)));
uicontrol('Parent',pAirpuff,'Style','text','String','Pulse length (s):','Units','normalized','Position',[0.05 0.60 0.55 0.10],'HorizontalAlignment','left');
handles.airpuff_pulse_len = uicontrol('Parent',pAirpuff,'Style','edit','String','0.05','Units','normalized','Position',[0.62 0.60 0.30 0.10],'BackgroundColor','white');
set(handles.airpuff_pulse_len,'Callback',@(h,e) airpuff_pulse_len_Callback(h,e,guidata(h)));
uicontrol('Parent',pAirpuff,'Style','text','String','# of pulses:','Units','normalized','Position',[0.05 0.44 0.55 0.10],'HorizontalAlignment','left');
handles.airpuff_n_pulses = uicontrol('Parent',pAirpuff,'Style','edit','String','1','Units','normalized','Position',[0.62 0.44 0.30 0.10],'BackgroundColor','white');
set(handles.airpuff_n_pulses,'Callback',@(h,e) airpuff_n_pulses_Callback(h,e,guidata(h)));
uicontrol('Parent',pAirpuff,'Style','text','String','Total time (s):','Units','normalized','Position',[0.05 0.28 0.55 0.10],'HorizontalAlignment','left');
handles.airpuff_total_time = uicontrol('Parent',pAirpuff,'Style','edit','String','0.05','Units','normalized','Position',[0.62 0.28 0.30 0.10],'BackgroundColor','white');
set(handles.airpuff_total_time,'Callback',@(h,e) airpuff_total_time_Callback(h,e,guidata(h)));

% --- Paired sub-panel
pPaired = uipanel('Parent',pTask,'Title','Paired (audio + airpuff)','Units','normalized','Position',[0.68 0.05 0.30 0.90]);
handles.paired_yes = uicontrol('Parent',pPaired,'Style','checkbox','String','Include paired trials','Value',1,'Units','normalized','Position',[0.05 0.85 0.9 0.12]);
set(handles.paired_yes,'Callback',@(h,e) paired_yes_Callback(h,e,guidata(h)));
uicontrol('Parent',pPaired,'Style','text','String',{'Paired trials play the tone(s)', 'configured in the Audio panel', 'and trigger the airpuff at the', 'same time (simultaneous onset).'}, ...
    'Units','normalized','Position',[0.05 0.45 0.90 0.35],'HorizontalAlignment','left');
uicontrol('Parent',pPaired,'Style','text','String','Trial/stim duration (s):','Units','normalized','Position',[0.05 0.22 0.65 0.14],'HorizontalAlignment','left');
handles.stim_dur = uicontrol('Parent',pPaired,'Style','edit','String','2','Units','normalized','Position',[0.70 0.22 0.25 0.14],'BackgroundColor','white');
set(handles.stim_dur,'Callback',@(h,e) stim_dur_Callback(h,e,guidata(h)));

%%%%% Runtime panel (ITI settings)
pRun = uipanel('Parent',fig,'Title','Runtime (ITI)','Units','normalized','Position',[0.02 0.020 0.96 0.100]);
uicontrol('Parent',pRun,'Style','text','String','ITI min (s):','Units','normalized','Position',[0.03 0.55 0.28 0.35],'HorizontalAlignment','left');
handles.iti_min = uicontrol('Parent',pRun,'Style','edit','String','20','Units','normalized','Position',[0.32 0.55 0.15 0.35],'BackgroundColor','white');
set(handles.iti_min,'Callback',@(h,e) iti_min_Callback(h,e,guidata(h)));
uicontrol('Parent',pRun,'Style','text','String','ITI max (s):','Units','normalized','Position',[0.50 0.55 0.28 0.35],'HorizontalAlignment','left');
handles.iti_max = uicontrol('Parent',pRun,'Style','edit','String','40','Units','normalized','Position',[0.79 0.55 0.15 0.35],'BackgroundColor','white');
set(handles.iti_max,'Callback',@(h,e) iti_max_Callback(h,e,guidata(h)));
uicontrol('Parent',pRun,'Style','text','String','Initial ITI (s):','Units','normalized','Position',[0.03 0.10 0.35 0.35],'HorizontalAlignment','left');
handles.iti_initial = uicontrol('Parent',pRun,'Style','edit','String','20','Units','normalized','Position',[0.40 0.10 0.15 0.35],'BackgroundColor','white');
set(handles.iti_initial,'Callback',@(h,e) iti_initial_Callback(h,e,guidata(h)));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% WINDOW 2: TRIAL BLOCK & RUN %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig2 = figure('Units','pixels','Position',[50 60 1150 850], ...
    'Name','PairedStimuli - Trial Block & Run','MenuBar','none','ToolBar','none', ...
    'NumberTitle','off','Resize','on','Tag','figure2');
handles.figure2 = fig2;

%%%%% Trial Block panel (set block size, generate/editw/preview trials)
pBlock = uipanel('Parent',fig2,'Title','Trial Block','Units','normalized','Position',[0.02 0.625 0.96 0.355]);
uicontrol('Parent',pBlock,'Style','text','String','# trials in block (300+ OK):','Units','normalized','Position',[0.02 0.90 0.34 0.08],'HorizontalAlignment','left');
handles.n_trials = uicontrol('Parent',pBlock,'Style','edit','String','30','Units','normalized','Position',[0.37 0.90 0.09 0.08],'BackgroundColor','white');
set(handles.n_trials,'Callback',@(h,e) n_trials_Callback(h,e,guidata(h)));
handles.generate_block = uicontrol('Parent',pBlock,'Style','pushbutton','String','Generate Block','Units','normalized','Position',[0.49 0.89 0.18 0.10]);
set(handles.generate_block,'Callback',@(h,e) generate_block_Callback(h,e,guidata(h)));

% left half: editable per-trial table
handles.block_table = uitable('Parent',pBlock,'Units','normalized','Position',[0.02 0.04 0.45 0.82], ...
    'ColumnName',{'Trial#','Modality','Freq (kHz)','Level','ITI (s)'}, ...
    'ColumnFormat',{'numeric',{'audio' 'airpuff' 'paired'},'numeric','numeric','numeric'}, ...
    'ColumnEditable',[false true true true true], ...
    'RowName',[]);
set(handles.block_table,'CellEditCallback',@(h,e) block_table_CellEditCallback(h,e,guidata(h)));

% right half: colored block preview + legend
handles.blockPreviewAxes = axes('Parent',pBlock,'Units','normalized','Position',[0.52 0.22 0.46 0.64]);
uicontrol('Parent',pBlock,'Style','text','String','Audio','Units','normalized','Position',[0.52 0.04 0.14 0.09], ...
    'BackgroundColor',[0.85 0.15 0.15],'ForegroundColor','white','FontWeight','bold');
uicontrol('Parent',pBlock,'Style','text','String','Airpuff','Units','normalized','Position',[0.68 0.04 0.14 0.09], ...
    'BackgroundColor',[0.15 0.35 0.85],'ForegroundColor','white','FontWeight','bold');
uicontrol('Parent',pBlock,'Style','text','String','Paired','Units','normalized','Position',[0.84 0.04 0.14 0.09], ...
    'BackgroundColor',[0.55 0.15 0.65],'ForegroundColor','white','FontWeight','bold');

%%%%% Run panel
pGo = uipanel('Parent',fig2,'Title','Run','Units','normalized','Position',[0.02 0.565 0.96 0.045]);
handles.run_setup_ok = uicontrol('Parent',pGo,'Style','pushbutton','String','Setup OK','Units','normalized','Position',[0.02 0.15 0.30 0.70],'Enable','off');
set(handles.run_setup_ok,'Callback',@(h,e) run_setup_ok_Callback(h,e,guidata(h)));
handles.run_start = uicontrol('Parent',pGo,'Style','pushbutton','String','Start','Units','normalized','Position',[0.35 0.15 0.30 0.70],'Enable','off');
set(handles.run_start,'Callback',@(h,e) run_start_Callback(h,e,guidata(h)));
handles.run_stop = uicontrol('Parent',pGo,'Style','pushbutton','String','Stop','Units','normalized','Position',[0.68 0.15 0.30 0.70],'Enable','off');
set(handles.run_stop,'Callback',@(h,e) run_stop_Callback(h,e,guidata(h)));

%%%%% legend for the live acquisition plot below (colors match the
%%%%% plotting functions' own colors, e.g. daqSessionPlotEvent_
%%%%% BallVelocity.m, daqSessionPlotEvent_Reward.m, daqSessionPlotEvent_
%%%%% TTLin/Out.m, daqSessionPlotEvent_SalientStimuli.m -- see
%%%%% legendChip() below). One row now that there's a single plot axes.
legendChip(fig2,[0.030 0.515 0.100 0.035],'Pitch',        [0.6350 0.0780 0.1840],'white');
legendChip(fig2,[0.132 0.515 0.100 0.035],'Yaw',          [0.3010 0.7450 0.9330],'black');
legendChip(fig2,[0.234 0.515 0.100 0.035],'Roll',         [0      0.5000 0     ],'white');
legendChip(fig2,[0.336 0.515 0.100 0.035],'Reward',       [0.4660 0.6740 0.1880],'white');
legendChip(fig2,[0.438 0.515 0.100 0.035],'Lick',         [0.4940 0.1840 0.5560],'white');
legendChip(fig2,[0.540 0.515 0.100 0.035],'TTL Out',      [0.8500 0.3250 0.0980],'black');
legendChip(fig2,[0.642 0.515 0.100 0.035],'TTL In (1-4)', [0.9290 0.6940 0.1250],'black');
legendChip(fig2,[0.744 0.515 0.100 0.035],'Audio stim',   [0      0.4470 0.7410],'white');
legendChip(fig2,[0.846 0.515 0.100 0.035],'Airpuff stim', [0.3010 0.7450 0.9330],'black');

%%%%% live acquisition plot -- fills about half the window (used by
%%%%% daqSessionInitializeDataBuffer / daqSessionUpdateDataBuffer /
%%%%% daqSessionPlotEvent_SalientStimuli). SalientStimuli.m's second axes
%%%%% (Axes 2) is dropped: with daqSessionInitializeDataBuffer(1) (called
%%%%% in run_setup_ok_Callback), every signal (ball velocity, reward,
%%%%% lick, TTL in/out, salient-stimuli markers) is drawn on Axes 1 only
%%%%% -- Axes 2 was never fed anything, so there's nothing lost by
%%%%% removing it.
handles.axes1 = axes('Parent',fig2,'Units','normalized','Position',[0.04 0.02 0.92 0.48]);
title(handles.axes1,'Live Acquisition Signals (see legend above)');
% NOTE: title() (unlike ylabel/plotted data) survives the periodic
% cla(ax) calls in daqSessionUpdateDataBuffer.m, so this title stays put
% during a run; daqSessionPlotEvent_BallVelocity.m still overwrites the
% ylabel to 'velocity (V)' on every refresh, which is expected/unchanged.

% both windows share this one handles struct -- sync guidata on both so
% a callback triggered from either window can reach controls in the other
guidata(fig, handles);
guidata(fig2, handles);

% small colored label (a "chip") used to build the plot legend above --
% a plain uicontrol, not an axes child, so it survives the periodic
% cla(axes) calls made by daqSessionUpdateDataBuffer.m during a run
function legendChip(parent,position,label,color,textColor)
uicontrol('Parent',parent,'Style','text','String',[' ' label],'Units','normalized','Position',position, ...
    'BackgroundColor',color,'ForegroundColor',textColor,'FontSize',7,'FontWeight','bold','HorizontalAlignment','left');
