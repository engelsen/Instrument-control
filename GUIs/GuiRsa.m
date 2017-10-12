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
handles.output=hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = GuiRsa_OutputFcn(hObject, eventdata, handles) 
varargout{1}=handles.output;

function cent_freq_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function cent_freq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function span_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function span_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function start_freq_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function start_freq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rbw_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function rbw_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function average_no_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function average_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stop_freq_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function stop_freq_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in point_no.
function point_no_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function point_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in enable_avg.
function enable_avg_Callback(hObject, eventdata, handles)

% --- Executes on button press in fetch_single.
function fetch_single_Callback(hObject, eventdata, handles)

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)

% --- Executes on button press in reinit.
function reinit_Callback(hObject, eventdata, handles)