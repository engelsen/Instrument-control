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

% Last Modified by GUIDE v2.5 24-Oct-2017 22:02:39

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

set(handles.figure1,'WindowButtonUpFcn',@figure1_WindowButtonUpFcn);
setappdata(0,'h_main_plot',gcf);
setappdata(gcf,'x_data',0);
setappdata(gcf,'y_data',0);
setappdata(gcf,'x_ref',0);
setappdata(gcf,'y_ref',0);
setappdata(gcf,'x_analyze',0);
setappdata(gcf,'y_analyze',0);
setappdata(gcf,'x_analyze_done',0); % Data which has been analyze in x axis
setappdata(gcf,'y_analyze_done',0); % Data which has been analyze in y axis

setappdata(gcf,'general_plot_update',@update_axes);
setappdata(gcf,'x_label','dummy x');
setappdata(gcf,'y_label','dummy y');
setappdata(gcf,'Vertical_curs',[]); % Object which contain the vertical cursor
setappdata(gcf,'Horizontal_curs',[]);% Object which contain the Horizontal cursor
setappdata(gcf,'Vertical_ref_curs',[]); % Object which contain the vertical cursor for reference
setappdata(gcf,'Vertical_ref_state',0); % Status of vertial cursor for reference
setappdata(gcf,'x_BG',0);
setappdata(gcf,'y_BG',0);
setappdata(gcf,'V1',[]);       % Value of vertical V1 cursor
setappdata(gcf,'V2',[]);       % Value of vertical V2 cursor
setappdata(gcf,'H1',[]);       % Value of Horizontal H1 cursor
setappdata(gcf,'H2',[]);       % Value of Horizontal H2 cursor
setappdata(gcf,'Hcursor_toggle_state',0);% flag which shows the Horizontal curcor state
setappdata(gcf,'Vcursor_toggle_state',0);% flag which shows the Vertical curcor state

setappdata(gcf,'error_flag',0);  % a flag to show or not show the fitted data
setappdata(gcf,'overwite_flag',0);
setappdata(gcf,'y_log_flag',0); % a flag log scale in y axis
setappdata(gcf,'x_log_flag',0); % a flag log scale in x axis

setappdata(gcf,'show_data',1);   % a flag to show or not show the data
setappdata(gcf,'show_ref',0);    % a flag to show or not show the ref
setappdata(gcf,'show_fit_flag',0);    % a flag to show or not show the fitted data
setappdata(gcf,'fit_meta_data',0);    % a variable to store the analysis meta data
setappdata(gcf,'fit_meta_data_name','');    % a variable to store the analysis meta names
setappdata(gcf,'fit_meta_data_text_position',[0,0]);    % a variable to store position of the text 1-> topleft, 2->topright, 3->bottomleft, 4->bottomright

setappdata(gcf,'folder_path','');    % this variable contains the path for the session

setappdata(gcf,'ring_down_frequency',1e6);   % a global variable to store the central frequency of ringdown experement

setappdata(gcf,'Signle_Lorentizan_P1',0);   % Signle Lorentzian fit coeff P1
setappdata(gcf,'Signle_Lorentizan_P2',0);   % Signle Lorentzian fit coeff P2
setappdata(gcf,'Signle_Lorentizan_P3',0);   % Signle Lorentzian fit coeff P3
setappdata(gcf,'Signle_Lorentizan_C',0);    % Signle Lorentzian fit coeff C


setappdata(gcf,'Vpi',2);    % Default value for Vpi of EOM

setappdata(gcf,'g0',20000);
set(handles.num_int,'Enable','off');
set(handles.num_int,'Value',1);

update_axes

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


% --- Executes on selection change in InstrMenu.
function InstrMenu_Callback(hObject, eventdata, handles)
% hObject    handle to InstrMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns InstrMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from InstrMenu
device_no=get(hObject,'Value');
device_list=get(hObject,'String');
device_name=device_list{device_no};

switch device_name
    case 'Select the device'
        % updating global variables and updating the plot
        h_main_plot=getappdata(0,'h_main_plot');
        setappdata(h_main_plot,'x_data',0);
        setappdata(h_main_plot,'y_data',0);
        setappdata(h_main_plot,'x_label','dummy x');
        setappdata(h_main_plot,'y_label','dummy y');
        update_axes=getappdata(h_main_plot,'update_axes');
        
        feval(update_axes);
        
    case 'RT Oscilloscope 1 (Tektronix DPO 4034)'
        Oscilloscope_Tektronix_RT;
    case 'Oscilloscope 1 (Tektronix DPO 4034)'
        Oscilloscope_Tektronix;
    case 'Spectrum Analyzer (Agilent MXA)'
        MXA_Signal_Analyzer;
    case 'Network Analyzer (Agilent NA)'
        NA_Network_Analyzer;
    case 'UHF Lock-in Amplifier (Zurich Instrument)'
        UHF_Zurich_Instrument;
    case 'Auto Ringdown (Agilent NA)'
        Ringdown_Auto_NA;
    case 'Oscilloscope 2 (Agilent DSO7034A)'
        Oscilloscope_Agilent
    case 'RT Spectrum Analyzer (RSA)'
        RSA_Signal_Analyzer
end

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

% --- Executes on button press in Vertical_cursor.
function Vertical_cursor_Callback(hObject, eventdata, handles)
% hObject    handle to Vertical_cursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Vertical_cursor
h_main_plot=getappdata(0,'h_main_plot');

VC_state=get(hObject,'Value');

setappdata(h_main_plot,'Vcursor_toggle_state',VC_state);

axes=findobj(h_main_plot,'type','axes');

if(VC_state==1)
    Vertical_curs=Vertical_cursors(axes);
    setappdata(h_main_plot,'Vertical_curs',Vertical_curs);
    set(hObject, 'BackGroundColor',[0,1,.2]);
    set(handles.V1_Edit,'enable','on' )
    set(handles.V2_Edit,'enable','on' )
    set(handles.V1_V2_Edit,'enable','on' )
elseif(VC_state==0)
    Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
    Vertical_curs.off();
    set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
    
    set(handles.V1_Edit,'enable','inactive' )
    set(handles.V2_Edit,'enable','inactive' )
    set(handles.V1_V2_Edit,'enable','inactive' )
    
    set(handles.V1_Edit,'string','' )
    set(handles.V2_Edit,'string','' )
    set(handles.V1_V2_Edit,'string','' )
end

% --- Executes on button press in Horizontal_cursor.
function Horizontal_cursor_Callback(hObject, eventdata, handles)
% hObject    handle to Horizontal_cursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Horizontal_cursor
h_main_plot=getappdata(0,'h_main_plot');

VC_state=get(hObject,'Value');

setappdata(h_main_plot,'Hcursor_toggle_state',VC_state);

axes=findobj(h_main_plot,'type','axes');

if(VC_state==1)
    Horizontal_curs=Horizontal_cursors(axes);
    setappdata(h_main_plot,'Horizontal_curs',Horizontal_curs);
    set(hObject, 'BackGroundColor',[0,1,.2]);
    
    set(handles.H1_Edit,'enable','on' )
    set(handles.H2_Edit,'enable','on' )
    set(handles.H2_H1_Edit,'enable','on' )
elseif(VC_state==0)
    Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
    Horizontal_curs.off();
    set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
    
    set(handles.H1_Edit,'enable','inactive' )
    set(handles.H2_Edit,'enable','inactive' )
    set(handles.H2_H1_Edit,'enable','inactive' )
    
    set(handles.H1_Edit,'string','' )
    set(handles.H2_Edit,'string','' )
    set(handles.H2_H1_Edit,'string','' )
end

% --- Executes on button press in Center_cursor.
function Center_cursor_Callback(hObject, eventdata, handles)
% hObject    handle to Center_cursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h_main_plot=getappdata(0,'h_main_plot');


Hcursor_toggle_state=getappdata(h_main_plot,'Hcursor_toggle_state');
if (Hcursor_toggle_state==1)
    Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
    Horizontal_curs.off();
    Horizontal_curs.add();
end

Vcursor_toggle_state=getappdata(h_main_plot,'Vcursor_toggle_state');
if (Vcursor_toggle_state==1)
    Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
    Vertical_curs.off();
    Vertical_curs.add();
end

Vertical_ref_state=getappdata(h_main_plot,'Vertical_ref_state');
if (Vertical_ref_state==1)
    Vertical_ref_curs=getappdata(h_main_plot,'Vertical_ref_curs');
    Vertical_ref_curs.off();
    Vertical_ref_curs.add();
end

axes=findobj(h_main_plot,'type','axes');

function V1_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to V1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of V1_Edit as text
%        str2double(get(hObject,'String')) returns contents of V1_Edit as a double
% Hint: get(hObject,'Value') returns toggle state of Vertical_cursor
h_main_plot=getappdata(0,'h_main_plot');

axes=findobj(h_main_plot,'type','axes');


Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
v_curs_val=Vertical_curs.val();
Vertical_curs.off();
v_curs_val(1)=str2num(get(hObject,'String'));
Vertical_curs.add(v_curs_val);

% --- Executes during object creation, after setting all properties.
function V1_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to V1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function V2_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to V2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of V2_Edit as text
%        str2double(get(hObject,'String')) returns contents of V2_Edit as a double
h_main_plot=getappdata(0,'h_main_plot');

axes=findobj(h_main_plot,'type','axes');

Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
v_curs_val=Vertical_curs.val();
Vertical_curs.off();
v_curs_val(2)=str2num(get(hObject,'String'));
Vertical_curs.add(v_curs_val);

% --- Executes during object creation, after setting all properties.
function V2_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to V2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function V1_V2_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to V1_V2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of V1_V2_Edit as text
%        str2double(get(hObject,'String')) returns contents of V1_V2_Edit as a double

% --- Executes during object creation, after setting all properties.
function V1_V2_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to V1_V2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function H1_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to H1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of H1_Edit as text
%        str2double(get(hObject,'String')) returns contents of H1_Edit as a double
h_main_plot=getappdata(0,'h_main_plot');

axes=findobj(h_main_plot,'type','axes');

Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
h_curs_val=Horizontal_curs.val();
Horizontal_curs.off();
h_curs_val(1)=str2num(get(hObject,'String'));
Horizontal_curs.add(h_curs_val);

% --- Executes during object creation, after setting all properties.
function H1_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to H1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function H2_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to H2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of H2_Edit as text
%        str2double(get(hObject,'String')) returns contents of H2_Edit as a double
h_main_plot=getappdata(0,'h_main_plot');

axes=findobj(h_main_plot,'type','axes');

Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
h_curs_val=Horizontal_curs.val();
Horizontal_curs.off();
h_curs_val(2)=str2num(get(hObject,'String'));
Horizontal_curs.add(h_curs_val);

% --- Executes during object creation, after setting all properties.
function H2_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to H2_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function H2_H1_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to H2_H1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of H2_H1_Edit as text
%        str2double(get(hObject,'String')) returns contents of H2_H1_Edit as a double

% --- Executes during object creation, after setting all properties.
function H2_H1_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to H2_H1_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in AnalyzeMenu.
function AnalyzeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AnalyzeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AnalyzeMenu

h_main_plot=getappdata(0,'h_main_plot');

analysis_routine_number=get(hObject,'Value');
axes=findobj(h_main_plot,'type','axes');

switch analysis_routine_number
    case 5
        Vertical_ref_curs=Vertical_cursors_ref(axes);
        setappdata(h_main_plot,'Vertical_ref_curs',Vertical_ref_curs);
        setappdata(h_main_plot,'Vertical_ref_state',1);
        
        set(findall(handles.RecordPanel, '-property', 'visible'), 'visible', 'off');
        set(handles.num_int,'Enable','off' );
        %Cases which use recording panel
    case 9
        set(findall(handles.RecordPanel, '-property', 'visible'), 'visible', 'on');
        set(handles.num_int,'Enable','off' );
        %Cases which use numerical integration panel
    case 6
        set(handles.num_int,'Enable','on' );
    otherwise
        Vertical_ref_curs=getappdata(h_main_plot,'Vertical_ref_curs');
        setappdata(h_main_plot,'Vertical_ref_state',0);
        if ~isempty(Vertical_ref_curs)
            Vertical_ref_curs.off();
        end
        set(handles.num_int,'Enable','off' );
        set(findall(handles.RecordPanel, '-property', 'visible'), 'visible', 'off');
end

% setappdata(h_main_plot,'Vcursor_toggle_state',VC_ref_state);

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


% --- Executes on selection change in Trace.
function Trace_Callback(hObject, eventdata, handles)
% hObject    handle to Trace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Trace contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Trace


% --- Executes during object creation, after setting all properties.
function Trace_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Trace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Analyse.
function Analyse_Callback(hObject, eventdata, handles)
% hObject    handle to Analyse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h_main_plot=getappdata(0,'h_main_plot');

if(get(handles.Trace,'Value')==1)
    x_data=getappdata(h_main_plot,'x_data');
    y_data=getappdata(h_main_plot,'y_data');
    
    setappdata(h_main_plot,'x_analyze',x_data);
    setappdata(h_main_plot,'y_analyze',y_data);
    
    x_analyze=x_data;
    y_analyze=y_data;
else
    x_ref=getappdata(h_main_plot,'x_ref');
    y_ref=getappdata(h_main_plot,'y_ref');
    
    setappdata(h_main_plot,'x_analyze',x_ref);
    setappdata(h_main_plot,'y_analyze',y_ref);
    
    x_analyze=x_ref;
    y_analyze=y_ref;
end

% check if the verital cursor is on
Vcursor_toggle_state=getappdata(h_main_plot,'Vcursor_toggle_state');
if (Vcursor_toggle_state==1)
    % set the left and right cursor from the cursor lines
    Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
    v_curs_val=Vertical_curs.val();
    setappdata(h_main_plot,'V1',v_curs_val(1));
    setappdata(h_main_plot,'V2',v_curs_val(2));
else
    % set the left and right to limits of the data
    setappdata(h_main_plot,'V1',min(x_analyze));
    setappdata(h_main_plot,'V2',max(x_analyze));
end

% check if the Hriozontal cursor is on
Hcursor_toggle_state=getappdata(h_main_plot,'Hcursor_toggle_state');
if (Hcursor_toggle_state==1)
    % set the up and down cursor from the cursor lines
    Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
    H_curs_val=Horizontal_curs.val();
    setappdata(h_main_plot,'H1',H_curs_val(1));
    setappdata(h_main_plot,'H2',H_curs_val(2));
else
    % set the up and down to limits of the data
    setappdata(h_main_plot,'H1',min(y_analyze));
    setappdata(h_main_plot,'H2',max(y_analyze));
end


switch get(handles.AnalyzeMenu,'Value')
    case 2
        knife_edge_calibration;
    case 3
        Single_Lorentzian_fit;
    case 4
        Lorentzian_interference_fit;
    case 5
        Double_Lorentzian_fit;
    case 6
        g0_calibration;
    case 7
        Calibration_Vpi;
    case 8
        Long_range_laser_sweep;
    case 9
        Exponencial_fit;
    case 10
        Resonant_Heating
    case 11
        Resonant_Heating_cal;
    case 12
        T_measurement;
end

%Placeholders
function DataToRef_Callback(~,~,~)%#ok<DEFNU>
function ShowData_Callback(~,~,~)%#ok<DEFNU>
function ShowRef_Callback(~,~,~) %#ok<DEFNU>
function BaseDir_Callback(~,~,~)%#ok<DEFNU>

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


% --- Executes on button press in open_folder.
function open_folder_Callback(hObject, eventdata, handles)
% hObject    handle to open_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Here we open the file and store its name and path for next steps

folder_name = uigetdir('C:\Users\ghadimi\Desktop');
set(handles.BaseDir,'string',[folder_name,'\']);



function SessionName_Callback(hObject, eventdata, handles)
% hObject    handle to SessionName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SessionName as text
%        str2double(get(hObject,'String')) returns contents of SessionName as a double


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

%Placeholder, defined in MyDaq
function FileName_Callback(hObject, eventdata, handles)

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


% --- Executes on button press in AutoName.
function AutoName_Callback(hObject, eventdata, handles)
% hObject    handle to AutoName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AutoName


%Callback now defined in class MyDaq.
function SaveData_Callback(~, ~, ~) %#ok<DEFNU>
function SaveRef_Callback(~, ~, ~) %#ok<DEFNU>

% --- Executes on button press in load_file.
function load_file_Callback(hObject, eventdata, handles)
% hObject    handle to load_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

folder_name=get(handles.BaseDir,'string');
if(isempty(folder_name))
    warning('Please input a valid folder name for loading a trace');
    folder_name=pwd;
end

try
    [FileName,PathName]=uigetfile('.txt','Select the trace',folder_name);
    full_path=[PathName,FileName];
    data_file=load(full_path');
catch
    error('Please select a valid file');
end

h_main_plot=getappdata(0,'h_main_plot');

if (get(handles.Load_data,'value')==1)
    setappdata(h_main_plot,'x_data',data_file(:,1));
    setappdata(h_main_plot,'y_data',data_file(:,2));
    
    %Makes the trace visible when loaded
    set(handles.ShowData,'Value',1);
    setappdata(h_main_plot,'show_data',1);
    set(handles.ShowData, 'BackGroundColor',[0,1,.2]);
    
else
    setappdata(h_main_plot,'x_ref',data_file(:,1));
    setappdata(h_main_plot,'y_ref',data_file(:,2));
    
    %Makes the trace visible when loaded
    set(handles.ShowRef,'Value',1);
    setappdata(h_main_plot,'show_ref',1);
    set(handles.ShowRef, 'BackGroundColor',[0,1,.2]);
end

update_axes

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an mainplot background. Strangely this
% needs to exist to make the VerticalCursors work
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
%Not sure what this is
function Untitled_1_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function Save_figure_Callback(hObject, eventdata, handles)
% hObject    handle to Save_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load the main data object of this analysis
h_main_plot=getappdata(0,'h_main_plot');


% Store the data trace
x_data=getappdata(h_main_plot,'x_data');
y_data=getappdata(h_main_plot,'y_data');

% Store the ref trace
x_ref=getappdata(h_main_plot,'x_ref');
y_ref=getappdata(h_main_plot,'y_ref');

% Store the labels of the plot
x_label=getappdata(h_main_plot,'x_label');
y_label=getappdata(h_main_plot,'y_label');

% Store the flags used to enable/disable data and ref in plot
show_data=getappdata(h_main_plot,'show_data');
show_ref=getappdata(h_main_plot,'show_ref');


% Choosing the file name and its destinaiton
% folder_name=get(handles.BaseDir,'string'); % The pre assumption of the folder path
folder_name=getappdata(h_main_plot,'folder_path');

[FileName,PathName] = uiputfile('*.jpg','Save as',folder_name);

% Defining a new figure made temprory for export
ftmp = figure;

% Depend on the status of the show flags plot the data and ref traces
if (show_data==1 && show_ref==0)
    plot(x_data,y_data,'b')
elseif ((show_data==0 && show_ref==1))
    plot(x_ref,y_ref,'k')
elseif ((show_data==1 && show_ref==1))
    plot(x_ref,y_ref,'k')
    hold on
    plot(x_data,y_data,'b')
    hold off
else
    plot(0,0)
end

% Check if the show analyzed data flag is on, plot the analyzed data
show_fit_flag=getappdata(h_main_plot,'show_fit_flag');    % a flag to show or not show the fitted data
if(show_fit_flag==1)
    hold on
    x_analyze_done=getappdata(h_main_plot,'x_analyze_done'); % Data which has been analyze in x axis
    y_analyze_done=getappdata(h_main_plot,'y_analyze_done'); % Data which has been analyze in y axis
    plot(x_analyze_done,y_analyze_done,'r')
    hold off
    fit_meta_data=getappdata(h_main_plot,'fit_meta_data');    % a variable to store the analysis meta data
    fit_meta_data_name=getappdata(h_main_plot,'fit_meta_data_name');    % a variable to store the analysis meta data
    text_position=getappdata(h_main_plot,'fit_meta_data_text_position');    % a variable to store position of the text fo meta data (first is x and second y)
    
    str=[fit_meta_data_name(:,:) num2str(fit_meta_data(:),4) ];
    text_opj=text(0,0,str,'Fontsize',14 ,'BackgroundColor',[1 1 1],'EdgeColor','red',...
        'VerticalAlignment','top',...
        'HorizontalAlignment','left');
    buffer=1/50;
    % set the text position
    set(text_opj,'units','normalized');
    fit_meta_data_text_position=getappdata(h_main_plot,'fit_meta_data_text_position');
    if(fit_meta_data_text_position==1)
        set(text_opj,'Position',[  buffer,1-buffer]);
        set(text_opj,'HorizontalAlignment','Left');
        set(text_opj,'VerticalAlignment','Top');
    elseif(fit_meta_data_text_position==2)
        set(text_opj,'Position',[1-buffer, 1- buffer]);
        set(text_opj,'HorizontalAlignment','Right');
        set(text_opj,'VerticalAlignment','Top');
    elseif(fit_meta_data_text_position==3)
        set(text_opj,'Position',[buffer,  buffer]);
        set(text_opj,'HorizontalAlignment','Left');
        set(text_opj,'VerticalAlignment','Bottom');
    elseif(fit_meta_data_text_position==4)
        set(text_opj,'Position',[1-buffer,  buffer]);
        set(text_opj,'HorizontalAlignment','Right');
        set(text_opj,'VerticalAlignment','Bottom');
    end
end

% Enableing the grid
grid on;

% Putting the x and y lables
xlabel(x_label);
ylabel(y_label);

new_axes=findobj(ftmp,'type','axes');

% Check if the X and Y axis should be linear or log scale
if(getappdata(h_main_plot,'y_log_flag')==1)
    set(new_axes,'yscale','log');
else
    set(new_axes,'yscale','linear');
end
if(getappdata(h_main_plot,'x_log_flag')==1)
    set(new_axes,'xscale','log');
else
    set(new_axes,'xscale','linear');
end

if(getappdata(h_main_plot,'y_log_flag')==1)
    % Now ploting the cursors:
    % check to see if the there is Horizontal cursors or not
    Hcursor_toggle_state=getappdata(h_main_plot,'Hcursor_toggle_state');
    if (Hcursor_toggle_state==1)
        Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
        h_curs_val=Horizontal_curs.val();    % store the value of the horizontal cursor
        Horizontal_cursors(new_axes,h_curs_val); % Make new cursors in the same position
        
    end
    % check to see if the there is Vertical cursors or not
    Vcursor_toggle_state=getappdata(h_main_plot,'Vcursor_toggle_state');
    if (Vcursor_toggle_state==1)
        Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
        v_curs_val=Vertical_curs.val(); % store the value of the horizontal cursor
        Vertical_cursors(new_axes,v_curs_val); % Make new cursors in the same position
    end
end

% Definig an style for exported image
myStyle = hgexport('factorystyle');
myStyle.Format = 'jpg';
myStyle.Width = 8;
myStyle.Height = 4;
myStyle.Resolution = 600;
myStyle.Units = 'inch';
% myStyle.FixedFontSize = 12;

% Exporting the image
hgexport(ftmp,[PathName,FileName] ,myStyle,'Format','jpeg')

% Deleting the figure
delete(ftmp);

%Placeholders
function LogY_Callback(~, ~, ~) %#ok<DEFNU>
function LogX_Callback(~, ~, ~) %#ok<DEFNU>

% --- Executes on button press in Clear_fit.
function Clear_fit_Callback(hObject, eventdata, handles)
% hObject    handle to Clear_fit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% import the main data object
h_main_plot=getappdata(0,'h_main_plot');

% Check if the show analyzed data flag is on, turn it off or Vise versa
show_fit_flag=getappdata(h_main_plot,'show_fit_flag');    % a flag to show or not show the fitted data
if(show_fit_flag==1)
    setappdata(h_main_plot,'show_fit_flag',0);    % reset the flag to zero
end


update_axes

% This is the main function of this window which update the axis with the
% proper plots (ref or data) and cursors
function update_axes
% First we load the main object of this program which store all variables
% and functions used to communicate with general plot window
h_main_plot=getappdata(0,'h_main_plot');

% First we check is the status flag for Horizontal cursor is off or on and
% if it is on, we
Hcursor_toggle_state=getappdata(h_main_plot,'Hcursor_toggle_state');
if (Hcursor_toggle_state==1)
    Horizontal_curs=getappdata(h_main_plot,'Horizontal_curs');
    h_curs_val=Horizontal_curs.val();
    Horizontal_curs.off();
end
Vcursor_toggle_state=getappdata(h_main_plot,'Vcursor_toggle_state');
if (Vcursor_toggle_state==1)
    Vertical_curs=getappdata(h_main_plot,'Vertical_curs');
    v_curs_val=Vertical_curs.val();
    Vertical_curs.off();
end

Vertical_ref_state=getappdata(h_main_plot,'Vertical_ref_state');
if (Vertical_ref_state==1)
    Vertical_ref_curs=getappdata(h_main_plot,'Vertical_ref_curs');
    v_ref_curs_val=Vertical_ref_curs.val();
    Vertical_ref_curs.off();
end

x_data=getappdata(h_main_plot,'x_data');
y_data=getappdata(h_main_plot,'y_data');

x_ref=getappdata(h_main_plot,'x_ref');
y_ref=getappdata(h_main_plot,'y_ref');

x_label=getappdata(h_main_plot,'x_label');
y_label=getappdata(h_main_plot,'y_label');

show_data=getappdata(h_main_plot,'show_data');
show_ref=getappdata(h_main_plot,'show_ref');

axes=findobj(h_main_plot,'type','axes');

if (show_data==1 && show_ref==0)
    plot(axes,x_data,y_data,'b')
elseif ((show_data==0 && show_ref==1))
    plot(axes,x_ref,y_ref,'k')
elseif ((show_data==1 && show_ref==1))
    plot(axes,x_ref,y_ref,'k')
    hold(axes, 'on');
    plot(axes,x_data,y_data,'b')
    hold(axes, 'off');
else
    plot(axes,0,0)
end

% Check if the show analyzed data flag is on, plot the analyzed data
show_fit_flag=getappdata(h_main_plot,'show_fit_flag');    % a flag to show or not show the fitted data
if(show_fit_flag==1)
    hold(axes, 'on');
    x_analyze_done=getappdata(h_main_plot,'x_analyze_done'); % Data which has been analyze in x axis
    y_analyze_done=getappdata(h_main_plot,'y_analyze_done'); % Data which has been analyze in y axis
    plot(axes,x_analyze_done,y_analyze_done,'r')
    hold(axes, 'off');
end

xlabel(axes,x_label);
ylabel(axes,y_label);

if(getappdata(h_main_plot,'y_log_flag')==1);
    set(axes,'yscale','log');
end
if(getappdata(h_main_plot,'x_log_flag')==1);
    set(axes,'xscale','log');
end

if (Hcursor_toggle_state==1)
    Horizontal_curs=Horizontal_cursors(axes,h_curs_val);
    setappdata(h_main_plot,'Horizontal_curs',Horizontal_curs);
end

if (Vcursor_toggle_state==1)
    Vertical_curs=Vertical_cursors(axes,v_curs_val);
    setappdata(h_main_plot,'Vertical_curs',Vertical_curs);
end

if (Vertical_ref_state==1)
    Vertical_ref_curs=Vertical_cursors_ref(axes,v_ref_curs_val);
    setappdata(h_main_plot,'Vertical_ref_curs',Vertical_ref_curs);
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

%Placeholders, callbacks defined in class
function DataToBg_Callback(~,~,~) %#ok<DEFNU>
function RefToBg_Callback(~,~,~) %#ok<DEFNU>
function ClearBg_Callback(~,~,~) %#ok<DEFNU>


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


% --- Executes on button press in num_int.
function num_int_Callback(hObject, eventdata, handles)
% hObject    handle to num_int (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of num_int
