function createGui(this)

%Makes the fit name have the first letter capitalized
fit_name=[upper(this.fit_name(1)),this.fit_name(2:end)];

%Defines the colors for the Gui
rgb_blue=[0.1843,0.4157,1];
rgb_white=[1,1,1];

%Width of the edit boxes in the GUI
edit_width=140;

%Height of buttons in GUI
button_h=25;

%Minimum height of the four vboxes composing the gui.
title_h=40;
equation_h=80;
savebox_h=60;
slider_h=100;

%Finds the minimum height in button heights of the user field panel. This
%is used to calculate the height of the figure.
tab_fields=fieldnames(this.UserGui.Tabs);
max_fields=max(cellfun(@(x) length(this.UserGui.Tabs.(x).Children),tab_fields));
if max_fields>3
    min_user_h=max_fields+2;
else
    min_user_h=5;
end

userpanel_h=min_user_h*button_h;
fig_h=title_h+equation_h+slider_h+userpanel_h;

%Name sets the title of the window, NumberTitle turns off the FigureN text
%that would otherwise be before the title, MenuBar is the menu normally on
%the figure, toolbar is the toolbar normally on the figure.
%HandleVisibility refers to whether gcf, gca etc will grab this figure.
this.Gui.Window = figure('Name', 'MyFit', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'Toolbar', 'none', 'HandleVisibility', 'off',...
    'Units','Pixels','Position',[500,500,edit_width*this.n_params,fig_h]);
%Sets the close function (runs when x is pressed) to be class function
set(this.Gui.Window, 'CloseRequestFcn',...
    @(hObject,eventdata) closeFigure(this, hObject,eventdata));
%The main vertical box. The four main panes of the GUI are stacked in the
%box. We create these four boxes first so that we do not need to redraw
%them later
this.Gui.MainVbox=uix.VBox('Parent',this.Gui.Window,'BackgroundColor','w');
%The title box
this.Gui.Title=annotation(this.Gui.MainVbox,'textbox',[0.5,0.5,0.3,0.3],...
    'String',fit_name,'Units','Normalized',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',16,'BackgroundColor',rgb_white);
%Displays the fitted equation
this.Gui.Equation=annotation(this.Gui.MainVbox,'textbox',[0.5,0.5,0.3,0.3],...
    'String',this.fit_tex,...
    'Units','Normalized','Interpreter','LaTeX',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',20,'BackgroundColor',rgb_white);
%Creates an HBox for extracted parameters and user interactions with GUI
this.Gui.UserHbox=uix.HBox('Parent',this.Gui.MainVbox,...
    'BackgroundColor',rgb_white);

%Creates the HBox for saving parameters
this.Gui.SaveHBox=uix.HBox('Parent',this.Gui.MainVBox,...
    'BackgroundColor',rgb_white);
%Creates the HBox for the fitting parameters
this.Gui.FitHbox=uix.HBox('Parent',this.Gui.MainVbox);

%Sets the heights and minimum heights of the four vertical boxes. -1 means
%it resizes with the window
set(this.Gui.MainVbox,'Heights',[title_h,-1,-1,slider_h],...
    'MinimumHeights',[title_h,equation_h,userpanel_h,slider_h]);

%Here we create the fit panel in the GUI.
this.Gui.FitPanel=uix.BoxPanel( 'Parent', this.Gui.UserHbox,...
    'Padding',0,'BackgroundColor', rgb_white,...
    'Title','Fit Panel','TitleColor',rgb_blue);
%Here we create the panel for the useful parameters
this.Gui.UserPanel=uix.BoxPanel( 'Parent', this.Gui.UserHbox,...
    'Padding',0,'BackgroundColor', 'w',...
    'Title','Calculated parameters','TitleColor',rgb_blue);

%This makes the buttons that go inside the FitPanel
this.Gui.FitVbox=uix.VBox('Parent',this.Gui.FitPanel,'BackgroundColor',...
    rgb_white);
%Creates the button for analysis inside the VBox
this.Gui.AnalyzeButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Analyze','Callback',...
    @(hObject, eventdata) analyzeCallback(this, hObject, eventdata));
%Creates button for generating new initial parameters
this.Gui.InitButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w',...
    'String','Generate Init. Params','Callback',...
    @(hObject, eventdata) initParamCallback(this, hObject, eventdata));
%Creates button for clearing fits
this.Gui.ClearButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Clear fits','Callback',...
    @(hObject, eventdata) clearFitCallback(this, hObject, eventdata));
this.Gui.SaveButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Save Fit',...
    'Callback', @(hObject, eventdata) saveCallback(this, hObject, eventdata));

set(this.Gui.FitVbox,'Heights',[button_h,button_h,button_h,button_h]);

this.Gui.TabPanel=uix.TabPanel('Parent',this.Gui.UserPanel,...
    'BackgroundColor',rgb_white);

%Creates the user values panel with associated tabs. The cellfun here
%creates the appropriately named tabs. To add a tab, add a new field to the
%UserGuiStruct.

usertabs=fieldnames(this.UserGui.Tabs);

if ~isempty(usertabs)
    cellfun(@(x) createTab(this,x,rgb_white,button_h),usertabs);
    this.Gui.TabPanel.TabTitles=...
        cellfun(@(x) this.UserGui.Tabs.(x).tab_title, usertabs,...
        'UniformOutput',0);
end

%We first make the BoxPanels to speed up the process. Otherwise everything
%in the BoxPanel must be redrawn every time we make a new one.
panel_str=cell(1,this.n_params);
for i=1:this.n_params
    %Generates the string for the panel handle
    panel_str{i}=sprintf('Panel_%s',this.fit_params{i});
    %Creates the panels
    this.Gui.(panel_str{i})=uix.BoxPanel( 'Parent', this.Gui.FitHbox ,...
        'Padding',0,'BackgroundColor', 'w',...
        'Title',sprintf('%s (%s)',this.fit_param_names{i},this.fit_params{i}),...
        'TitleColor',rgb_blue,...
        'Position',[1+edit_width*(i-1),1,edit_width,slider_h],...
        'Visible','off');
end

%Loops over number of parameters to create a fit panel for each one
for i=1:this.n_params
    %Generates the string for the vbox handle
    vbox_str=sprintf('Vbox_%s',this.fit_params{i});
    %Generates the string for the slider handle
    slider_str=sprintf('Slider_%s',this.fit_params{i});
    %Generates string for edit panels
    edit_str=sprintf('Edit_%s',this.fit_params{i});
    
    %Creates the vbox inside the panel that allows stacking
    this.Gui.(vbox_str) =uix.VBox( 'Parent', ...
        this.Gui.(panel_str{i}),'Padding',0,'BackgroundColor', 'w');
    
    %Generates edit box for fit parameters
    this.Gui.(edit_str)=uicontrol('Parent',this.Gui.(vbox_str),...
        'Style','edit','String',sprintf('%3.3e',this.init_params(i)),...
        'FontSize',14,'Tag',edit_str,'HorizontalAlignment','Right',...
        'Position',[1,48,edit_width-4,30],'Units','Pixels','Callback',...
        @(hObject,eventdata) editCallback(this, hObject, eventdata));
    %Generates java-based slider. Looks nicer than MATLAB slider
    this.Gui.(slider_str)=uicomponent('Parent',this.Gui.(vbox_str),...
        'style','jslider','Value',50,'Orientation',0,...
        'MajorTickSpacing',20,'MinorTickSpacing',5,'Paintlabels',0,...
        'PaintTicks',1,'Background',java.awt.Color.white,...
        'pos',[1,-7,edit_width-4,55]);
    %Sets up callbacks for the slider
    this.Gui.([slider_str,'_callback'])=handle(this.Gui.(slider_str),...
        'CallbackProperties');
    this.Gui.([slider_str,'_callback']).StateChangedCallback = ....
        @(hObject, eventdata) sliderCallback(this,i,hObject,eventdata);
    this.Gui.([slider_str,'_callback']).MouseReleasedCallback = ....
        @(~, ~) triggerNewInitVal(this);
    %Sets heights and minimum heights for the elements in the fit vbox
    set(this.Gui.(vbox_str),'Heights',[30,55],'MinimumHeights',[30,55])
    
end

%Makes all the panels at the bottom visible at the same time
cellfun(@(x) set(this.Gui.(x),'Visible','on'),panel_str);

end