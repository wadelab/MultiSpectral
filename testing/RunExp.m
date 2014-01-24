function varargout = RunExp(varargin)
% RUNEXP MATLAB code for RunExp.fig
%      RUNEXP, by itself, creates a new RUNEXP or raises the existing
%      singleton*.
%
%      H = RUNEXP returns the handle to a new RUNEXP or the handle to
%      the existing singleton*.
%
%      RUNEXP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUNEXP.M with the given input arguments.
%
%      RUNEXP('Property','Value',...) creates a new RUNEXP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RunExp_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RunExp_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RunExp

% Last Modified by GUIDE v2.5 26-Apr-2013 15:51:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RunExp_OpeningFcn, ...
                   'gui_OutputFcn',  @RunExp_OutputFcn, ...
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


% --- Executes just before RunExp is made visible.
function RunExp_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RunExp (see VARARGIN)

% Choose default command line output for RunExp
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RunExp wait for user response (see UIRESUME)
% uiwait(handles.RunExp);


% --- Outputs from this function are returned to the command line.
function varargout = RunExp_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ParticipantID_Callback(hObject, eventdata, handles)
SubjectID=str2double(get(hObject,'String'));
assignin('base','SubjectID',SubjectID);

% hObject    handle to ParticipantID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ParticipantID as text
%        str2double(get(hObject,'String')) returns contents of ParticipantID as a double


% --- Executes during object creation, after setting all properties.
function ParticipantID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParticipantID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end






% --- Executes on selection change in ExperimentID.
function ExperimentID_Callback(hObject, eventdata, handles)
ExptID=get(hObject,'Value');
string_EXPlist = get(hObject,'String');
selected_EXPstring = str2num(string_EXPlist{ExptID}); 
assignin('base','ExptID',selected_EXPstring);
% hObject    handle to ExperimentID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ExperimentID contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ExperimentID


% --- Executes during object creation, after setting all properties.
function ExperimentID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExperimentID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ScanNumber.
function ScanNumber_Callback(hObject, eventdata, handles)
ScanNum=get(hObject,'Value');
string_SCANlist = get(hObject,'String');
selected_SCANstring = str2num(string_SCANlist{ScanNum}); 
assignin('base','ScanNum',selected_SCANstring);

% hObject    handle to ScanNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ScanNumber contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ScanNumber


% --- Executes during object creation, after setting all properties.
function ScanNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScanNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in Start.
function Start_Callback(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
    close RunExp
end
% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function Start_CreateFcn(hObject, eventdata, handles)


% hObject    handle to Start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when user attempts to close RunExp.
function RunExp_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to RunExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
