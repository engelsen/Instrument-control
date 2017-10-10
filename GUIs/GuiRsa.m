function varargout = GuiRsa(varargin)
% GuiRsa MATLAB code for GuiRsa.fig
%      GuiRsa, by itself, creates a new GuiRsa or raises the existing
%      singleton*.
%
%      H = GuiRsa returns the handle to a new GuiRsa or the handle to
%      the existing singleton*.
%
%      GuiRsa('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GuiRsa.M with the given input arguments.
%
%      GuiRsa('Property','Value',...) creates a new GuiRsa or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiRsa_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiRsa_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiRsa

% Last Modified by GUIDE v2.5 09-Oct-2017 16:20:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GuiRsa_OpeningFcn, ...
                   'gui_OutputFcn',  @GuiRsa_OutputFcn, ...
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


% --- Executes just before GuiRsa is made visible.
function GuiRsa_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiRsa (see VARARGIN)

% Choose default command line output for GuiRsa
handles.output=hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = GuiRsa_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
varargout{1}=handles.output;


function cent_freq_Callback(hObject, eventdata, handles)
% hObject    handle to cent_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cent_freq as text
%        str2double(get(hObject,'String')) returns contents of cent_freq as a double

% --- Executes during object creation, after setting all properties.
function cent_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cent_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function span_Callback(hObject, eventdata, handles)
% hObject    handle to span (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of span as text
%        str2double(get(hObject,'String')) returns contents of span as a double


% --- Executes during object creation, after setting all properties.
function span_CreateFcn(hObject, eventdata, handles)
% hObject    handle to span (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function start_freq_Callback(hObject, eventdata, handles)
% hObject    handle to start_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_freq as text
%        str2double(get(hObject,'String')) returns contents of start_freq as a double

% --- Executes during object creation, after setting all properties.
function start_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rbw_Callback(hObject, eventdata, handles)
% hObject    handle to rbw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rbw as text
%        str2double(get(hObject,'String')) returns contents of rbw as a double



% --- Executes during object creation, after setting all properties.
function rbw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rbw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function average_no_Callback(hObject, eventdata, handles)
% hObject    handle to average_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of average_no as text
%        str2double(get(hObject,'String')) returns contents of average_no as a double


% --- Executes during object creation, after setting all properties.
function average_no_CreateFcn(hObject, eventdata, handles)
% hObject    handle to average_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stop_freq_Callback(hObject, eventdata, handles)
% hObject    handle to stop_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stop_freq as text
%        str2double(get(hObject,'String')) returns contents of stop_freq as a double


% --- Executes during object creation, after setting all properties.
function stop_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stop_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in point_no.
function point_no_Callback(hObject, eventdata, handles)
% hObject    handle to point_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns point_no contents as cell array
%        contents{get(hObject,'Value')} returns selected item from point_no

% --- Executes during object creation, after setting all properties.
function point_no_CreateFcn(hObject, eventdata, handles)
% hObject    handle to point_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in enable_avg.
function enable_avg_Callback(hObject, eventdata, handles)
% hObject    handle to enable_avg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enable_avg

% --- Executes on button press in fetch_single.
function fetch_single_Callback(hObject, eventdata, handles)
% hObject    handle to fetch_single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fetch_single


% --- Executes on button press in fetch_avt.
function fetch_avt_Callback(hObject, eventdata, handles)
% hObject    handle to fetch_avt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fetch_avt


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure



% --- Executes on selection change in device.
function device_Callback(hObject, eventdata, handles)
% hObject    handle to device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns device contents as cell array
%        contents{get(hObject,'Value')} returns selected item from device
%use TCP/IP in Matlab
buffer = 1000 * 1024;
visa_brand = 'ni';
delete(handles.vi);
if get(hObject,'Value')==1
    visa_address_rsa = 'TCPIP0::192.168.1.3::inst0::INSTR';
else
    visa_address_rsa = 'TCPIP0::192.168.1.5::inst0::INSTR';
end
vi = visa(visa_brand, visa_address_rsa, 'InputBufferSize', buffer, ...
      'OutputBufferSize', buffer);
handles.vi=vi;
set(vi,'InputBufferSize',1e6);
set(vi,'Timeout',10);
fopen(vi);

%Read out / set initial settings
set(handles.cent_freq,'String',num2str(str2num(query(handles.vi,['DPSA:FREQ:CENT?']))/1e6));
set(handles.span,'String',num2str(str2num(query(handles.vi,['DPSA:FREQ:SPAN?']))/1e6));
set(handles.start_freq,'String',num2str(str2num(query(handles.vi,['DPSA:FREQ:STAR?']))/1e6));
set(handles.stop_freq,'String',num2str(str2num(query(handles.vi,['DPSA:FREQ:STOP?']))/1e6));
set(handles.rbw,'String',num2str(str2num(query(handles.vi,['DPSA:band:act?']))/1e3));
set(handles.average_no,'String','1');
fprintf(handles.vi,'TRAC3:DPSA:AVER:COUN 1');
set(handles.point_no,'Value',4);
fprintf(handles.vi,'DPSA:POIN:COUN P10401');

fclose(vi);

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function device_CreateFcn(hObject, eventdata, handles)
% hObject    handle to device (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reinit.
function reinit_Callback(hObject, eventdata, handles)
% hObject    handle to reinit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reinit
%Placeholder, callback redefined in class.
