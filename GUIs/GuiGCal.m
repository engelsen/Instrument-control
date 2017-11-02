function varargout = GuiGCal(varargin)
%GUIGCAL MATLAB code file for GuiGCal.fig
%      GUIGCAL, by itself, creates a new GUIGCAL or raises the existing
%      singleton*.
%
%      H = GUIGCAL returns the handle to a new GUIGCAL or the handle to
%      the existing singleton*.
%
%      GUIGCAL('Property','Value',...) creates a new GUIGCAL using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to GuiGCal_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      GUIGCAL('CALLBACK') and GUIGCAL('CALLBACK',hObject,...) call the
%      local function named CALLBACK in GUIGCAL.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiGCal

% Last Modified by GUIDE v2.5 02-Nov-2017 13:36:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GuiGCal_OpeningFcn, ...
                   'gui_OutputFcn',  @GuiGCal_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before GuiGCal is made visible.
function GuiGCal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for GuiGCal
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GuiGCal wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GuiGCal_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function v_RF_input_Callback(hObject, eventdata, handles)
% hObject    handle to v_RF_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of v_RF_input as text
%        str2double(get(hObject,'String')) returns contents of v_RF_input as a double


% --- Executes during object creation, after setting all properties.
function v_RF_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to v_RF_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function V_pi_input_Callback(hObject, eventdata, handles)
% hObject    handle to V_pi_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of V_pi_input as text
%        str2double(get(hObject,'String')) returns contents of V_pi_input as a double


% --- Executes during object creation, after setting all properties.
function V_pi_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to V_pi_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Temperature_Callback(hObject, eventdata, handles)
% hObject    handle to Temperature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Temperature as text
%        str2double(get(hObject,'String')) returns contents of Temperature as a double


% --- Executes during object creation, after setting all properties.
function Temperature_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Temperature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function Linewidth_Adj_Callback(hObject, eventdata, handles)
% hObject    handle to Linewidth_Adj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function Linewidth_Adj_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Linewidth_Adj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function beta_input_Callback(hObject, eventdata, handles)
% hObject    handle to beta_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of beta_input as text
%        str2double(get(hObject,'String')) returns contents of beta_input as a double


% --- Executes during object creation, after setting all properties.
function beta_input_CreateFcn(hObject, eventdata, handles)
% hObject    handle to beta_input (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
