function varargout = GuiScope(varargin)
% GUISCOPE MATLAB code for GuiScope.fig
%      GUISCOPE, by itself, creates a new GUISCOPE or raises the existing
%      singleton*.
%
%      H = GUISCOPE returns the handle to a new GUISCOPE or the handle to
%      the existing singleton*.
%
%      GUISCOPE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUISCOPE.M with the given input arguments.
%
%      GUISCOPE('Property','Value',...) creates a new GUISCOPE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiScope_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiScope_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiScope

% Last Modified by GUIDE v2.5 12-Oct-2017 18:16:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GuiScope_OpeningFcn, ...
                   'gui_OutputFcn',  @GuiScope_OutputFcn, ...
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


% --- Executes just before GuiScope is made visible.
function GuiScope_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiScope (see VARARGIN)





% Choose default command line output for GuiScope
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);




% UIWAIT makes GuiScope wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% Connecting to the device
% Oscilloscope_initialization(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = GuiScope_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on selection change in channel_select.
function channel_select_Callback(hObject, eventdata, handles)
% hObject    handle to channel_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_select


% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function channel_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Update handles structure


% --- Executes on button press in fetch_single.
function fetch_single_Callback(hObject, eventdata, handles)
% hObject    handle to fetch_single (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    channel_list_content=(get(handles.channel_select,'Value')); 

    switch channel_list_content
        case 1
            handles.channel='channel1';
        case 2
            handles.channel='channel2';
        case 3 
            handles.channel='channel3';
        case 4 
            handles.channel='channel4';
        otherwise 
            handles.channel='channel1';
    end

    % Execute device object function(s).
    waveform = get(handles.deviceObj, 'Waveform');
    waveform = waveform(1);
    set(waveform, 'Precision', 'int16');
    [y,x] = invoke(waveform, 'readwaveform', handles.channel);




    % updating global variables and updating the plot
    h_main_plot=getappdata(0,'h_main_plot');
    setappdata(h_main_plot,'x_data',x);
    setappdata(h_main_plot,'y_data',y);
    setappdata(h_main_plot,'y_label','Voltage (V)');
    setappdata(h_main_plot,'x_label','Time(s)');
    update_axes=getappdata(h_main_plot,'update_axes');

    feval(update_axes);




% --- Executes on button press in reinit.
function reinit_Callback(hObject, eventdata, handles)
% hObject    handle to reinit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Oscilloscope_initialization(hObject,handles)


% --- Executes on button press in cont_read.
function cont_read_Callback(hObject, eventdata, handles)
% hObject    handle to cont_read (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cont_read

continous_stat=get(hObject,'Value');

channel_list_content=(get(handles.channel_select,'Value')); 

switch channel_list_content
    case 1
        handles.channel='channel1';
    case 2
        handles.channel='channel2';
    case 3 
        handles.channel='channel3';
    case 4 
        handles.channel='channel4';
    otherwise 
        handles.channel='channel1';
end

while (continous_stat==1)
    % Execute device object function(s).
    waveform = get(handles.deviceObj, 'Waveform');
    waveform = waveform(1);
    set(waveform, 'Precision', 'int16');
    [y,x] = invoke(waveform, 'readwaveform', handles.channel);




    % updating global variables and updating the plot
    h_main_plot=getappdata(0,'h_main_plot');
    setappdata(h_main_plot,'x_data',x);
    setappdata(h_main_plot,'y_data',y);
    setappdata(h_main_plot,'y_label','Voltage (V)');
    setappdata(h_main_plot,'x_label','Time(s)');
    update_axes=getappdata(h_main_plot,'update_axes');

    feval(update_axes);

    drawnow;
 
    continous_stat=get(hObject,'Value');
    
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%delete(handles.interfaceObj);
delete(handles.deviceObj);
delete(handles.interfaceObj);
delete(hObject);
