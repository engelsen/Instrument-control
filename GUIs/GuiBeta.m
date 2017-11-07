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

% Last Modified by GUIDE v2.5 07-Nov-2017 13:48:51

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



%%%%*********************************************************************************%%%%
%%%%----------------------------The V_pi program ------------------------------------%%%%
%%%%*********************************************************************************%%%%
function Vp_calibration(hObject, eventdata, handles)


% First we need to load the data object of the main program (general plot)
% this object contains many global variabl which shares and updated by
% other programs of DAQ
h_main_plot=getappdata(0,'h_main_plot');

% Load the data trace to be analyze
x_analyze=getappdata(h_main_plot,'x_analyze');  % x axis vector
y_analyze=getappdata(h_main_plot,'y_analyze');  % y axis vector

% We need to make sure the data in a column and not row 
if ~iscolumn(x_analyze)
     x_analyze=x_analyze';
 end
  if ~iscolumn(y_analyze)
     y_analyze=y_analyze';
 end

% set the left and right cursor from the cursor lines
temp(1)=getappdata(h_main_plot,'V1');
temp(2)=getappdata(h_main_plot,'V2');
% sort the cursor values
temp=sort(temp);
left_cursor=temp(1);
right_cursor=temp(2);

% find the index of the cursors
[~,left_cursor_index]=min(abs(x_analyze-left_cursor));
[~,right_cursor_index]=min(abs(x_analyze-right_cursor));

% take the fraction of the data which sits between the two cursor
freq_v_pi=x_analyze(left_cursor_index:right_cursor_index);
S_v_pi=y_analyze(left_cursor_index:right_cursor_index);


% Finding the index of the the centeral maximum and the side bands
min_peak_distance=200;      % The minimum distance (number of points) between mechanics and EOM
[peaks_S_vpi,locs] = findpeaks(S_v_pi,freq_v_pi,'minpeakdistance',min_peak_distance); % The local peaks are sorted from small to large
A=sortrows([peaks_S_vpi locs]);
A=sortrows(A(end-4:end,:),2);

index_center_peak=find(freq_v_pi==A(3,2));  % We find the position of the AOM peak (Centeral one)

% Then we find the position of the EOM sidebands peak by checking their
% frequencies
index_center_left=find(freq_v_pi==A(2,2));
index_center_right=find(freq_v_pi==A(4,2));

index_center_left_2=find(freq_v_pi==A(1,2));
index_center_right_2=find(freq_v_pi==A(5,2));

% To remove the point noise we use the statistic of other point by using
% the curve fitting. The fitting function should be the window function of
% the spectrum analyzer wihch is near to Gaussian.

n=10;   % number of the points in each side of the peak used for fitting (optimized to have minimum "mean sqoure error")

% Finding the avarage of the noise over the area where there is no peak (between the centeral frequency and the left sideband)
mean_Noise_index_left=floor((index_center_peak+index_center_left)/2);
mean_noise_left=mean(S_v_pi(mean_Noise_index_left-n:mean_Noise_index_left+n));

mean_Noise_index_right=floor((index_center_peak+index_center_right)/2);
mean_noise_right=mean(S_v_pi(mean_Noise_index_right-n:mean_Noise_index_right+n));

mean_noise=(mean_noise_left+mean_noise_right)/2;

% Selecting the part of the data in the neighborhood of the central peak
% and fitting a Gaussian to it
S_center_peak=S_v_pi(index_center_peak-n:index_center_peak+n);
f_center_peak=freq_v_pi(index_center_peak-n:index_center_peak+n);
S_center_fit=fit(f_center_peak,S_center_peak-mean_noise,'gauss1');

% Selecting the part of the data in the neighborhood of the left peak
% and fitting a Gaussian to it
S_left_peak=S_v_pi(index_center_left-n:index_center_left+n);
f_left_peak=freq_v_pi(index_center_left-n:index_center_left+n);
S_left_fit=fit(f_left_peak,S_left_peak-mean_noise_left,'gauss1');

% Selecting the part of the data in the neighborhood of the right peak
% and fitting a Gaussian to it
S_right_peak=S_v_pi(index_center_right-n:index_center_right+n);
f_right_peak=freq_v_pi(index_center_right-n:index_center_right+n);
S_right_fit=fit(f_right_peak,S_right_peak-mean_noise_right,'gauss1');

% Selecting the part of the data in the neighborhood of the 2nd left peak
% and fitting a Gaussian to it
S_left_peak_2=S_v_pi(index_center_left_2-n:index_center_left_2+n);
f_left_peak_2=freq_v_pi(index_center_left_2-n:index_center_left_2+n);
S_left_fit_2=fit(f_left_peak_2,S_left_peak_2-mean_noise_left,'gauss1');

% Selecting the part of the data in the neighborhood of the 2nd right peak
% and fitting a Gaussian to it
S_right_peak_2=S_v_pi(index_center_right_2-n:index_center_right_2+n);
f_right_peak_2=freq_v_pi(index_center_right_2-n:index_center_right_2+n);
S_right_fit_2=fit(f_right_peak_2,S_right_peak_2-mean_noise_right,'gauss1');

if(getappdata(h_main_plot,'Num_Int')==0)
    % Here we numerically calculate the total fit curve (in whole spectrum)
    % which has three gaussian and we plot it
    Fitted_curve_tot=feval(S_center_fit,freq_v_pi)+feval(S_left_fit,freq_v_pi)+feval(S_right_fit,freq_v_pi)+mean_noise;


    % In the next step, we need just find the peaks of these three and plot it
    S_peaks=[S_v_pi(index_center_left),S_v_pi(index_center_peak),S_v_pi(index_center_right)];
    f_peaks=[freq_v_pi(index_center_left),freq_v_pi(index_center_peak),freq_v_pi(index_center_right)];


    % Now in the last step we need to calculate the RMS values for the voltage.
    % One can shoe that the RMS value is equal to the root of the area under
    % each Gaussian. We have analytically calculate the Gaussian=a*exp(-((x-b)/c)^2)
    % The area is equal to "area= a*c*sqrt(pi)"

    % RMS voltage of the central peak
    coeff_center=coeffvalues(S_center_fit); % Taking the Gaussian coefficient
    area_center=(coeff_center(1)*sqrt(pi))*abs(coeff_center(3))

    % RMS voltage of the left sideband
    coeff_left=coeffvalues(S_left_fit); % Taking the Gaussian coefficient
    area_left=(coeff_left(1)*sqrt(pi))*abs(coeff_left(3))

    % RMS voltage of the right sideband
    coeff_right=coeffvalues(S_right_fit); % Taking the Gaussian coefficient
    area_right=(coeff_right(1)*sqrt(pi))*abs(coeff_right(3))
    % Setting the show fit flag to 1
    setappdata(h_main_plot,'show_fit_flag',1);
    % Now we can store the analyzed data
    setappdata(h_main_plot,'x_analyze_done',freq_v_pi); % Data which has been analyze in x axis
    setappdata(h_main_plot,'y_analyze_done',Fitted_curve_tot); % Data which has been analyze in y axis
else
    area_center=trapz(f_center_peak,S_center_peak);
    area_left=trapz(f_left_peak,S_left_peak);
    area_right=trapz(f_right_peak,S_right_peak);
    area_left_2=trapz(f_left_peak_2,S_left_peak_2);
    area_right_2=trapz(f_right_peak_2,S_right_peak_2);
    setappdata(h_main_plot,'show_fit_flag',0);
end

% RMS voltages of the peaks
V_RMS_Center=sqrt(area_center);
V_RMS_left=sqrt(area_left);
V_RMS_right=sqrt(area_right);
V_RMS_left_2=sqrt(area_left_2);
V_RMS_right_2=sqrt(area_right_2);

% Then we can calculate the FM beta by using: beta= 0.5*(V_RMS_right+V_RMS_left)/V_RMS_Center;
%handles.beta=(V_RMS_right+V_RMS_left)/V_RMS_Center;
sdratio_01 = 0.5*(V_RMS_right+V_RMS_left)/V_RMS_Center;
sdratio_02 = 0.5*(V_RMS_right_2+V_RMS_left_2)/V_RMS_Center;
sdratio_12 = (V_RMS_right_2+V_RMS_left_2)/(V_RMS_right+V_RMS_left);
syms b;
handles.beta_01 = double(vpasolve(besselj(1,b) == sdratio_01 * besselj(0,b), b, 2*sdratio_01));
handles.beta_02 = double(vpasolve(besselj(2,b) == sdratio_02 * besselj(0,b), b, 2*sdratio_02));
handles.beta_12 = double(vpasolve(besselj(2,b) == sdratio_12 * besselj(1,b), b, 2*sdratio_12));

% In the next step we calculate the applied voltage to EOM to calculate the
% v_pi
% P_RF = str2num(get(handles.v_RF_input,'String')); %Power applied to EOM in dBm
% R_ref= 50;  %50 ohm reference resistance
% V_RF_RMS=sqrt(10^(P_RF/10)*(1e-3)*R_ref); % RMS value of the EOM applied voltage
% 
% V_pi_RMS=pi*V_RF_RMS/handles.beta_02;  % V_pi_RMS which is the modulation depth

% Seting the output string
set(handles.Beta02,'String',num2str(handles.beta_02,5));
set(handles.Beta01,'String',num2str(handles.beta_01,5));
set(handles.Beta12,'String',num2str(handles.beta_12,5));
% set(handles.v_pi_out_RMS,'String',num2str(V_pi_RMS,3));
% set(handles.v_pi_out_peak,'String',num2str(V_pi_RMS*sqrt(2),3));

%setappdata(h_main_plot,'Vpi',V_pi_RMS);    % Default value for Vpi of EOM
setappdata(h_main_plot,'Beta',handles.beta_02);
%setappdata(h_main_plot,'RF_power',P_RF);

% unpading the general plot axec
general_plot_update=getappdata(h_main_plot,'general_plot_update');    
feval(general_plot_update);

%%%%*********************************************************************************%%%%
%%%%----------------------------End of V_pi program ---------------------------------%%%%
%%%%*********************************************************************************%%%%
