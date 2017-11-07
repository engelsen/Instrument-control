function varargout = GuiBeta(varargin)
% GUIBETA MATLAB code for GuiBeta.fig
%      GUIBETA, by itself, creates a new GUIBETA or raises the existing
%      singleton*.
%
%      H = GUIBETA returns the handle to a new GUIBETA or the handle to
%      the existing singleton*.
%
%      GUIBETA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUIBETA.M with the given input arguments.
%
%      GUIBETA('Property','Value',...) creates a new GUIBETA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GuiBeta_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GuiBeta_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GuiBeta

% Last Modified by GUIDE v2.5 07-Nov-2017 17:35:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GuiBeta_OpeningFcn, ...
                   'gui_OutputFcn',  @GuiBeta_OutputFcn, ...
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


% --- Executes just before GuiBeta is made visible.
function GuiBeta_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GuiBeta (see VARARGIN)

% Choose default command line output for GuiBeta
handles.output = hObject;


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GuiBeta wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GuiBeta_OutputFcn(hObject, eventdata, handles) 
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
Vp_calibration(hObject, eventdata, handles);

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

% --- Executes on button press in AnalyzeButton.
function AnalyzeButton_Callback(hObject, eventdata, handles)
% hObject    handle to AnalyzeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
