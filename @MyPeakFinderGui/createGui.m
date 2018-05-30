function createGui(this)
fit_list={'Lorentzian','Double Lorentzian', 'Gorodetsky2000'};
fig_width=1000;
fig_h=800;

row_height=50;
col_width=120;
x_first_col=50;

button_size=[100,30];
edit_size=[100,30];
file_edit_size=[200,30];
h_first_row=fig_h-row_height;
h_second_row=fig_h-2*row_height;
h_third_row=fig_h-3*row_height;

%Name sets the title of the window, NumberTitle turns off the FigureN text
%that would otherwise be before the title, MenuBar is the menu normally on
%the figure, toolbar is the toolbar normally on the figure.
%HandleVisibility refers to whether gcf, gca etc will grab this figure.
this.Gui.Window = figure('Name', 'PeakFinder',...
    'NumberTitle', 'off', ...
    'MenuBar','none',...
    'Toolbar','figure',...
    'HandleVisibility', 'off',...
    'Units','Pixels',...
    'Position',[200,400,fig_width,fig_h],...
    'WindowScrollWheelFcn',@(src, event) windowScrollCallback(this, src, event));
%Sets the close function (runs when x is pressed) to be class function
set(this.Gui.Window, 'CloseRequestFcn',...
    @(src,event) closeFigure(this, src, event));

%Creates axis
this.axis_handle=axes(this.Gui.Window,...
    'Box','on',...
    'Units','Pixels',...
    'Position',[50,50,fig_width-100,fig_h-6*row_height]);
hold(this.axis_handle,'on');
this.axis_handle.ButtonDownFcn=@(src, event) clickCallback(this, src, event);
%Button for doing the analysis
this.Gui.AnalyzeButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col,h_first_row,button_size],...
    'String','Analyze',...
    'Callback',@(src, event) analyzeCallback(this, src, event));

%Checkbox for finding minima
this.Gui.MinimaCheck=uicontrol(this.Gui.Window,...
    'Style','checkbox',...
    'Units','Pixels',...
    'Position',[x_first_col+90,h_second_row,button_size],...
    'Value',0);
this.Gui.MinimaLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col,h_second_row,[80,30]],...
    'String','Find minima',...
    'Enable','off');

%Button for clearing the data
this.Gui.FitButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col,h_third_row,button_size],...
    'String','Fit peaks',...
    'Callback',@(src, event) fitPeakCallback(this, src, event));

%Button for clearing the data
this.Gui.ClearButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+col_width,h_first_row,button_size],...
    'String','Clear',...
    'Callback',@(src, event) clearCallback(this, src, event));

%Button for loading the trace 
this.Gui.LoadTraceButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+4*col_width,h_first_row,button_size],...
    'String','Load trace',...
    'Callback',@(src, event) loadTraceCallback(this, src, event));

this.Gui.PromLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col+2*col_width,h_first_row,edit_size],...
    'String','Prominence',...
    'Enable','off');
%Button for changing the peak threshold
this.Gui.PromEdit=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','Pixels',...
    'Position',[x_first_col+3*col_width,h_first_row,edit_size],...
    'String','0.5');

this.Gui.SepLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col+2*col_width,h_second_row,edit_size],...
    'String','Res. Separation',...
    'Enable','off');
%Button for changing the resonance separation
this.Gui.SepEdit=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','Pixels',...
    'Position',[x_first_col+3*col_width,h_second_row,edit_size],...
    'String','1');

%Button for saving the peaks
this.Gui.SavePeaksButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+4*col_width,h_second_row,button_size],...
    'String','Save Peaks',...
    'Callback',@(src, event) savePeaksCallback(this, src, event));

%Button for loading peaks
this.Gui.LoadPeaksButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+4*col_width,h_third_row,button_size],...
    'String','Load Peaks',...
    'Callback',@(src, event) loadPeaksCallback(this, src, event));

%Button for clearing the peaks
this.Gui.ClearPeaksButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+col_width,h_second_row,button_size],...
    'String','Clear peaks',...
    'Callback',@(src, event) clearPeaksCallback(this, src, event));

this.Gui.BaseLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col+5*col_width,h_first_row,edit_size],...
    'String','Base directory',...
    'Enable','off');
%Button for changing the peak threshold
this.Gui.BaseEdit=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','Pixels',...
    'Position',[x_first_col+6*col_width,h_first_row,file_edit_size],...
    'String','M:\Measurement Campaigns');


this.Gui.SessionLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col+5*col_width,h_second_row,edit_size],...
    'String','Session name',...
    'Enable','off');
%Editbox for changing the session name
this.Gui.SessionEdit=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','Pixels',...
    'Position',[x_first_col+6*col_width,h_second_row,file_edit_size],...
    'String','placeholder');


this.Gui.FileNameLabel=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','pixels',...
    'Position',[x_first_col+5*col_width,h_third_row,edit_size],...
    'String','File name',...
    'Enable','off');
%Editbox for changing the filename
this.Gui.FileNameEdit=uicontrol(this.Gui.Window,...
    'Style','edit',...
    'Units','Pixels',...
    'Position',[x_first_col+6*col_width,h_third_row,file_edit_size],...
    'String','placeholder');

%For selecting fits
this.Gui.FitList=uicontrol(this.Gui.Window,...
    'Style','listbox',...
    'Units','Pixels',...
    'String',fit_list,...
    'Position',[x_first_col+col_width,h_third_row-1.5*row_height,...
    col_width,2*row_height]);

%For selecting fits
this.Gui.SelFitList=uicontrol(this.Gui.Window,...
    'Style','listbox',...
    'Units','Pixels',...
    'Position',[x_first_col+2.5*col_width,h_third_row-1.5*row_height,...
    col_width,2*row_height]);

%Add fit
this.Gui.RemoveFitButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+2.05*col_width,h_third_row-0.9*row_height,50,20],...
    'String','<<',...
    'Callback',@(src, event) removeFitCallback(this, src, event));

%Remove fit
this.Gui.RemoveFitButton=uicontrol(this.Gui.Window,...
    'Style','pushbutton',...
    'Units','Pixels',...
    'Position',[x_first_col+2.05*col_width,h_third_row-0.4*row_height,50,20],...
    'String','>>',...
    'Callback',@(src, event) addFitCallback(this, src, event));


end