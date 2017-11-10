function varargout = GuiDaq(varargin)
% GUIDAQ MATLAB code for GuiDaq.fig
%      GUIDAQ, by itself, creates a new GUIDAQ or raises the existing
%      singleton*.
%
%      H = GUIDAQ returns the handle to a new GUIDAQ or the handle to
%      the existing singleton*.
%
%      GUIDAQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIDAQ.M with the given input arguments.
%
%      GUIDAQ('Property','Value',...) creates a new GUIDAQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiDaq_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiDaq_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiDaq

% Last Modified by GUIDE v2.5 06-Nov-2017 16:13:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GuiDaq_OpeningFcn, ...
    'gui_OutputFcn',  @GuiDaq_OutputFcn, ...
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

% --- Executes just before GuiDaq is made visible.
function GuiDaq_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiDaq (see VARARGIN)

% Choose default command line output for GuiDaq
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = GuiDaq_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function InstrMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InstrMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditV1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditV1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditV2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditV2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditV2V1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditV2V1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditH1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditH1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditH2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditH2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function EditH2H1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EditH2H1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function AnalyzeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AnalyzeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function SelTrace_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SelTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function BaseDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BaseDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function SessionName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SessionName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function FileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in record.
function record_Callback(hObject, eventdata, handles)
% hObject    handle to record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Takes the data from the fit
try
    h_main_plot=getappdata(0,'h_main_plot');
    fit_meta_data=getappdata(h_main_plot,'fit_meta_data');
    
    f=fit_meta_data(1);
    lw=fit_meta_data(2);
    Q=fit_meta_data(3);
catch
    error('No fit parameters found')
end

%Standardized save path
save_path=[handles.Drive_Letter,':\Measurement Campaigns\'];

%Checks if a session name and file name is given
if ~isstr(get(handles.SessionName,'string'))
    error('No session name given')
elseif ~isstr(get(handles.FileName,'string'))
    error('No file name given')
end

%Puts the date in front of the session name
session_name=[datestr(now,'yyyy-mm-dd '),...
    get(handles.SessionName,'string'),'\'];

%Makes the path if it does not exist
if ~exist([save_path,session_name],'dir')
    mkdir(save_path,session_name);
end

%Full path
final_path=[save_path,session_name,'Q factor','.txt'];

%Creates the file if it does not exist, otherwise opens the file
if ~exist(final_path,'file')
    fileID=fopen(final_path,'w');
    %Creates headers in the file
    fmt=['%s\t%s\t%s\t\t%s\t%s\t\r\n'];
    fprintf(fileID,fmt,'Beam#','f(MHz)','Q(10^6)','Q*f(10^14)','lw');
else
    fileID=fopen(final_path,'a');
end

%Formatting string
fmt=['%s\t%3.3f\t%3.3f\t\t%3.3f\t\t%3.3f\r\n'];
tag=get(handles.edit_tag,'string');
fprintf('Data saved in %s',final_path);
%Reshapes the data in appropriate units
fprintf(fileID,fmt,tag{1},f/1e6,Q/1e6,Q*f/1e14,lw);
fclose(fileID);

function edit_tag_Callback(hObject, eventdata, handles)
% hObject    handle to edit_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_tag as text
%        str2double(get(hObject,'String')) returns contents of edit_tag as a double


% --- Executes during object creation, after setting all properties.
function edit_tag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_tag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Subtract_BG.
function Subtract_BG_Callback(hObject, eventdata, handles)
% hObject    handle to Subtract_BG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Subtract_BG
h_main_plot=getappdata(0,'h_main_plot');
if (get(hObject,'Value')==1)
    set(hObject, 'BackGroundColor',[0,1,.2]);
    y_data=getappdata(h_main_plot,'y_data')-getappdata(h_main_plot,'y_BG');
else
    set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
    y_data=getappdata(h_main_plot,'y_data')+getappdata(h_main_plot,'y_BG');
end
setappdata(h_main_plot,'y_data',y_data);
update_axes


% --- Executes on button press in togglebutton9.
function togglebutton9_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton9


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function DestTrc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DestTrc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
