% Mai-Anh Vu, 10/2/2021
% edited 2/21/2022 for 2 LEDs
function varargout = SalientStimuli(varargin)
global session % our global variable to store everything
% SalientStimuli MATLAB code for SalientStimuli.fig
%      SalientStimuli, by itself, creates a new SalientStimuli or raises the existing
%      singleton*.
%
%      H = SalientStimuli returns the handle to a new SalientStimuli or the handle to
%      the existing singleton*.
%
%      SalientStimuli('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SalientStimuli.M with the given input arguments.
%
%      SalientStimuli('Property','Value',...) creates a new SalientStimuli or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the SalientStimuli before SalientStimuli_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SalientStimuli_OpeningFcn via varargin.
%
%      *See SalientStimuli Options on GUIDE's Tools menu.  Choose "SalientStimuli allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SalientStimuli

% Last Modified by GUIDE v2.5 19-Feb-2022 15:03:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SalientStimuli_OpeningFcn, ...
                   'gui_OutputFcn',  @SalientStimuli_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before SalientStimuli is made visible.
function SalientStimuli_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SalientStimuli (see VARARGIN)

% Choose default command line output for SalientStimuli
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
global session
session.exp.tone.tone1.freq = str2double(get(handles.tone_freq,'String'));
session.exp.tone.tone1.vol = str2num(get(handles.tone_vol,'String'));


% UIWAIT makes SalientStimuli wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function output = SalientStimuli_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
global session
session.handles=handles;
output = session;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% SAVING OUTPUT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in save_path_button.
function save_path_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_path_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.save_path,'String',uigetdir(get(handles.save_path,'String')));


function save_path_Callback(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of save_path as text
%        str2double(get(hObject,'String')) returns contents of save_path as a double


% --- Executes during object creation, after setting all properties.
function save_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to save_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function filename_prefix_Callback(hObject, eventdata, handles)
% hObject    handle to filename_prefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filename_prefix as text
%        str2double(get(hObject,'String')) returns contents of filename_prefix as a double


% --- Executes during object creation, after setting all properties.
function filename_prefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filename_prefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% TASK SETUP %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in led_L.
function led_L_Callback(hObject, eventdata, handles)
% hObject    handle to led_L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of led_L
global session
if get(hObject,'Value') == 0
    set(handles.led_n_L,'Enable','off')    
    session.exp.ledL = 0;
else
    set(handles.led_n_L,'Enable','on')
    session.exp.ledL = str2num(get(handles.led_n_L,'String'));
end


% --- Executes during object creation, after setting all properties.
function led_n_L_CreateFcn(hObject, eventdata, handles)
% hObject    handle to led_n_L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function led_n_L_Callback(hObject, eventdata, handles)
% hObject    handle to led_n_L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of led_n_L as text
%        str2double(get(hObject,'String')) returns contents of led_n_L as a double
global session
if get(handles.led_L,'Value')==1
    session.exp.ledL = str2num(get(hObject,'String'));
else
    session.exp.ledL = 0;
end



% --- Executes on button press in led_R.
function led_R_Callback(hObject, eventdata, handles)
% hObject    handle to led_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of led_R
global session
if get(hObject,'Value') == 0
    set(handles.led_n_R,'Enable','off')    
    session.exp.ledR = 0;
else
    set(handles.led_n_R,'Enable','on')
    session.exp.ledR = str2num(get(handles.led_n_L,'String'));
end

function led_n_R_Callback(hObject, eventdata, handles)
% hObject    handle to led_n_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of led_n_R as text
%        str2double(get(hObject,'String')) returns contents of led_n_R as a double
global session
if get(handles.led_R,'Value')==1
    session.exp.ledR = str2num(get(hObject,'String'));
else
    session.exp.ledR = 0;
end


% --- Executes during object creation, after setting all properties.
function led_n_R_CreateFcn(hObject, eventdata, handles)
% hObject    handle to led_n_R (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tone_yes.
function tone_yes_Callback(hObject, eventdata, handles)
% hObject    handle to tone_yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tone_yes
if get(hObject,'Value') == 0
    set(handles.tone_n,'Enable','off')
    set(handles.tone_list,'Enable','off')
    set(handles.tone_freq,'Enable','off')
    set(handles.tone_vol,'Enable','off')
else
    set(handles.tone_n,'Enable','on')
    set(handles.tone_list,'Enable','on')
    set(handles.tone_freq,'Enable','on')
    set(handles.tone_vol,'Enable','on')
end
    

function tone_n_Callback(hObject, eventdata, handles)
% hObject    handle to tone_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tone_n as text
%        str2double(get(hObject,'String')) returns contents of tone_n as a double
global session
tone_n = str2double(get(handles.tone_n,'String'));
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

% --- Executes during object creation, after setting all properties.
function tone_n_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tone_n (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tone_vol_Callback(hObject, eventdata, handles)
% hObject    handle to tone_vol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tone_vol as text
%        str2double(get(hObject,'String')) returns contents of tone_vol as a double
% update values
global session
thisTone = ['tone' num2str(get(handles.tone_list,'Value'))];
session.exp.tone.(thisTone).vol = str2num(get(handles.tone_vol,'String'));

% --- Executes during object creation, after setting all properties.
function tone_vol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tone_vol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in tone_list.
function tone_list_Callback(hObject, eventdata, handles)
% hObject    handle to tone_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tone_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tone_list

% tone list
global session
% update tone list if necessary
tone_n = str2double(get(handles.tone_n,'String'));
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


% --- Executes during object creation, after setting all properties.
function tone_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tone_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tone_freq_Callback(hObject, eventdata, handles)
% hObject    handle to tone_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tone_freq as text
%        str2double(get(hObject,'String')) returns contents of tone_freq as a double
global session
thisTone = ['tone' num2str(get(handles.tone_list,'Value'))];
session.exp.tone.(thisTone).freq = str2double(get(handles.tone_freq,'String'));


% --- Executes during object creation, after setting all properties.
function tone_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tone_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function stim_dur_Callback(hObject, eventdata, handles)
% hObject    handle to stim_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stim_dur as text
%        str2double(get(hObject,'String')) returns contents of stim_dur as a double


% --- Executes during object creation, after setting all properties.
function stim_dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stim_dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% RUNTIME %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function iti_min_Callback(hObject, eventdata, handles)
% hObject    handle to iti_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iti_min as text
%        str2double(get(hObject,'String')) returns contents of iti_min as a double
if str2double(get(hObject,'String'))<0
    set(hObject,'String','0')
end
if str2double(get(hObject,'String'))>str2double(get(handles.iti_max,'String'))
    set(hObject,'String',get(handles.iti_max,'String'))
end

% --- Executes during object creation, after setting all properties.
function iti_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iti_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function iti_max_Callback(hObject, eventdata, handles)
% hObject    handle to iti_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iti_min as text
%        str2double(get(hObject,'String')) returns contents of iti_min as a double
if str2double(get(hObject,'String')) < str2double(get(handles.iti_min,'String'))
    set(hObject,'String',(get(handles.iti_min,'String')))
end
if str2double(get(hObject,'String'))<0
    set(hObject,'String','0')
end
if str2double(get(hObject,'String'))<str2double(get(handles.iti_min,'String'))
    set(hObject,'String',get(handles.iti_min,'String'))
end


% --- Executes during object creation, after setting all properties.
function iti_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iti_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function n_trials_Callback(hObject, eventdata, handles)
% hObject    handle to n_trials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of n_trials as text
%        str2double(get(hObject,'String')) returns contents of n_trials as a double


% --- Executes during object creation, after setting all properties.
function n_trials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_trials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function iti_initial_Callback(hObject, eventdata, handles)
% hObject    handle to iti_initial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of iti_initial as text
%        str2double(get(hObject,'String')) returns contents of iti_initial as a double


% --- Executes during object creation, after setting all properties.
function iti_initial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iti_initial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls susually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% SETUP FUNCTIONS %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function generateSalientStimTrialOrder
% columnns: LED/TONE, freq, brightness/vol level
% note that LED brightness level is handled manually
global session
rng shuffle
if ~isstruct(session.exp.tone) && session.exp.tone == 0
    nCues = double(sum(session.exp.ledL>0)>0) + double(sum(session.exp.ledR>0)>0);
else
    nCues = min([sum(session.exp.ledL>0)>0,1]) + min([sum(session.exp.ledR>0)>0,1]) + numel(fieldnames(session.exp.tone));
end
% LED first
ledmat = [];
if sum(session.exp.ledL>0)>0 % L first
    ledmat = [ledmat; zeros(round(session.exp.n_trials/nCues),3)];
    ledmat(:,2) = -1; % this is for sound frequency (-1 is L)
    n = round(size(ledmat,1)/numel(session.exp.ledL));
    ni = [0:numel(session.exp.ledL)]*n;
    ni(end) = size(ledmat,1);
    for i = 1:numel(session.exp.ledL)
        ledmat((ni(i)+1):ni(i+1),3) = session.exp.ledL(i);
    end    
end
%%%% SELF YOU ARE HERE %%%%%
if sum(session.exp.ledR>0)>0 % now R
    itmp = size(ledmat,1);
    ledmat = [ledmat; zeros(round(session.exp.n_trials/nCues),3)];    
    ledmat(itmp+1:end,2) = -2; % this is for sound frequency (-2 is R)
    n = round((size(ledmat,1)-itmp)/numel(session.exp.ledR));
    ni = itmp+[0:numel(session.exp.ledR)]*n;
    ni(end) = size(ledmat,1);
    for i = 1:numel(session.exp.ledR)
        ledmat((ni(i)+1):ni(i+1),3) = session.exp.ledR(i);
    end  
end
        
% tones    
if isstruct(session.exp.tone)
    tonemat = ones(session.exp.n_trials-size(ledmat,1),3);
    % loop over and assign frequencies
    n = round(size(tonemat,1)/numel(fieldnames(session.exp.tone)));
    ni = [0:numel(fieldnames(session.exp.tone))]*n;
    ni(end) = size(tonemat,1);
    for i = 1:numel(fieldnames(session.exp.tone))
        tonemat((ni(i)+1):ni(i+1),2) = session.exp.tone.(['tone' num2str(i)]).freq;
        % loop over and assign volume levels        
        theseTrials = tonemat((ni(i)+1):ni(i+1),3);
        m = round(size(theseTrials,1)/numel(session.exp.tone.(['tone' num2str(i)]).vol));
        mi = [0:numel(session.exp.tone.(['tone' num2str(i)]).vol)]*m;
        mi(end) = size(theseTrials,1);
        for j = 1:numel(session.exp.tone.(['tone' num2str(i)]).vol)
            theseTrials((mi(j)+1):mi(j+1)) = session.exp.tone.(['tone' num2str(i)]).vol(j);
        end
        tonemat((ni(i)+1):ni(i+1),3) = theseTrials;
    end       
else
    tonemat = [];
end
trialmat = [ledmat; tonemat];
% now scramble a bunch of times
for i = 500
    idx = randperm(size(trialmat,1));
    trialmat = trialmat(idx,:);
end
session.exp.trials = table(transpose(1:session.exp.n_trials),'VariableNames',{'trialNum'});
session.exp.trials.modality = trialmat(:,1);
session.exp.trials.frequency = trialmat(:,2);
session.exp.trials.level = trialmat(:,3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% PHOTOMETRY LEDs %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in led_470.
function led_470_Callback(hObject, eventdata, handles)
% hObject    handle to led_470 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of led_470


% --- Executes on button press in led_570.
function led_570_Callback(hObject, eventdata, handles)
% hObject    handle to led_570 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of led_570


% --- Executes on button press in led_405.
function led_405_Callback(hObject, eventdata, handles)
% hObject    handle to led_405 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of led_405


function rec_freq_Callback(hObject, eventdata, handles)
% hObject    handle to rec_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rec_freq as text
%        str2double(get(hObject,'String')) returns contents of rec_freq as a double


% --- Executes during object creation, after setting all properties.
function rec_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rec_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% RUN %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in run_setup_ok.
function run_setup_ok_Callback(hObject, eventdata, handles)
global session
% hObject    handle to run_setup_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
warning('off','daq:Session:onDemandOnlyChannelsAdded')
% disable a bunch of things from further editing
set(handles.save_path_button,'Enable','off')
set(handles.save_path,'Enable','off')
set(handles.filename_prefix,'Enable','off')
set(handles.led_L,'Enable','off')
set(handles.led_n_L,'Enable','off')
set(handles.led_R,'Enable','off')
set(handles.led_n_R,'Enable','off')
set(handles.tone_yes,'Enable','off')
set(handles.tone_n,'Enable','off')
set(handles.tone_list,'Enable','off')
set(handles.tone_freq,'Enable','off')
set(handles.tone_vol,'Enable','off')
set(handles.stim_dur,'Enable','off')
set(handles.iti_min,'Enable','off')
set(handles.iti_max,'Enable','off')
set(handles.iti_initial,'Enable','off')
set(handles.n_trials,'Enable','off')
set(handles.led_470,'Enable','off')
set(handles.led_570,'Enable','off')
set(handles.led_405,'Enable','off')
set(handles.rec_freq,'Enable','off')
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
session.exp.salient_stim = 1;
if get(handles.led_L,'Value') == 0
    session.exp.ledL = 0;
else
    session.exp.ledL = str2num(get(handles.led_n_L,'String'));
end
if get(handles.led_R,'Value') == 0
    session.exp.ledR = 0;
else
    session.exp.ledR = str2num(get(handles.led_n_R,'String'));
end
if get(handles.tone_yes,'Value')==0
    session.exp.tone = 0;
end      
session.exp.iti_interval = [str2double(get(handles.iti_min,'String')),...
    str2double(get(handles.iti_max,'String'))];
session.exp.iti_initial = str2double(get(handles.iti_initial,'String'));
session.exp.n_trials = str2double(get(handles.n_trials,'String'));
session.exp.stim_dur = str2double(get(handles.stim_dur,'String'));
% generate trial table
generateSalientStimTrialOrder;
% add in ITI
if range(session.exp.iti_interval)>0
    session.exp.trials.iti = transpose(randsample(session.exp.iti_interval(1):session.exp.iti_interval(2),session.exp.n_trials,1));
else
    session.exp.trials.iti = repmat(session.exp.iti_interval(1),session.exp.n_trials,1);
end
session.exp.trials.iti(1) = session.exp.iti_initial;

%%%%% initialize other things
daqSessionInitialize; 
BallInitialize;
SalientStimuli_Initialize;
% initialze LEDs
session.exp.LEDwavelengths = [470 570 405];
session.exp.LEDon = [get(handles.led_470,'Value'),...
    get(handles.led_570,'Value'),...
    get(handles.led_405,'Value')];
session.exp.LEDrecFreq = str2double(get(handles.rec_freq,'String'));
if sum(session.exp.LEDon)>0 && session.exp.LEDrecFreq>0
    session.exp.LED = 1;
    LEDInitialize; % initialize
end
% initialize TTL signals (in & out)
session.exp.ttlOut = 1;  
session.exp.ttlIn = 1;
TTLSyncInitialize; % initialize
%%%%% finalize setup
daqSessionInitializeDataBuffer(1); % initialize the data buffer for vis.
daqSessionInitializeOutputs; % gather the output channels and initialize

%%% enable start button
set(handles.run_start,'Enable','on') 


% --- Executes on button press in run_start.
function run_start_Callback(hObject, eventdata, handles)
global session % our global variable to store everything
% hObject    handle to run_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update buttons and editable text windows
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
% hObject    handle to run_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.run_stop,'Enable','off') % turn off the stop button
daqSessionClose; % close data acquisition session
% just in case the LED is stuck on
% add digital output channel (ao3) to trigger LED ANALOG stim
session.nidaq.s4 = daq.createSession('ni');
session.nidaq.s4.Rate = 1000; % samples/second 
%session.nidaq.s4.IsContinuous = 1; % continuous
[~,session.nidaqCh.outIdx_stimulus_led_analog] = addAnalogOutputChannel(session.nidaq.s4, session.temp.dev, 'ao3', 'Voltage');
session.nidaqCh.outIdx_stimulus_led_analog = session.nidaqCh.outIdx_stimulus_led_analog+1;
session.nidaq.s4.queueOutputData(zeros(500,1)); % send 0s in case
session.nidaq.s4.startBackground();
stop(session.nidaq.s4)
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

%clearvars % clear variables
close(gcbf) % close GUI
clear global % clear global variables

% see if you want to run another experiment
answer = questdlg('Start another session?', ...
	'Start another session?', ...
	'Yes','No','Yes');
% Handle response
switch answer
    case 'Yes'
        %close all
        run('SalientStimuli');
    case 'No'
        %close all
end

function trialUpdate
    global session
    
    % update some variables
    session.temp.ITI = session.exp.trials.iti(session.temp.currentTrial);
    session.temp.currentStim = session.exp.trials.modality(session.temp.currentTrial);
    session.temp.currentFreq = session.exp.trials.frequency(session.temp.currentTrial);
    session.temp.currentLevel = session.exp.trials.level(session.temp.currentTrial);
    
    % display trial information
    session.temp.stimLabel = {'LED','tone'};
    disp(['trial #' num2str(session.temp.currentTrial) ' in ' num2str(session.temp.ITI) 's:'])
    str1 = session.temp.stimLabel{session.temp.currentStim+1};
    if session.temp.currentStim==1
        str2 = [' ' num2str(session.temp.currentFreq) 'kHz'];
    else
        str2 = ' ';
    end
    str3 = [' level ' num2str(session.temp.currentLevel)];
    disp([str1 str2 str3])


