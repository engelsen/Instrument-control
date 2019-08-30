function createGui(this, varargin)

p=inputParser();
%Parameter that tells the function if save panel should be created
addParameter(p,'save_panel',true,@islogical);
parse(p,varargin{:});
enable_save_panel = p.Results.save_panel;

if ~isempty(this.fit_name)
    
    %Makes the fit name have the first letter capitalized
    fit_name=[upper(this.fit_name(1)),this.fit_name(2:end)];
else
    fit_name='';
end

%Defines the colors for the Gui
rgb_blue=[0.1843,0.4157,1];
rgb_white=[1,1,1];

%Width of the edit boxes in the GUI
edit_width=140;

%Height of buttons in GUI
button_h=25;

%Minimum height of the four vboxes composing the gui.
title_h=40;
equation_h=100;
savebox_h=100; %Only relevant when save_panel input argument is true
slider_h=130;

min_fig_width=560;

%Finds the height in button heights of the user field panel. This
%is used to calculate the height of the figure.
n_user_params = length(fieldnames(this.UserParamList));
if n_user_params>3
    userpanel_h=(n_user_params+2)*button_h;
else
    userpanel_h=6*button_h; % 6 is the number of buttons in the fit panel
end

if enable_save_panel
    fig_h=title_h+equation_h+slider_h+savebox_h+userpanel_h;
else
    fig_h=title_h+equation_h+slider_h+userpanel_h;
end

%Sets a minimum width
if this.n_params < 4 
    if this.n_params ~= 0
        edit_width=min_fig_width/this.n_params; 
    else
        
        % Support the case of dummy fit with no parameters
        edit_width=min_fig_width;
    end
end
fig_width=edit_width*this.n_params;

%Name sets the title of the window, NumberTitle turns off the FigureN text
%that would otherwise be before the title, MenuBar is the menu normally on
%the figure, toolbar is the toolbar normally on the figure.
%HandleVisibility refers to whether gcf, gca etc will grab this figure.
this.Gui.Window = figure('Name', 'MyFit', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'Toolbar', 'none', 'HandleVisibility', 'off',...
    'Units','Pixels','Position',[100,100,fig_width,fig_h]);

%Place the figure in the center of the screen
centerFigure(this.Gui.Window);

%Sets the close function (runs when x is pressed) to be class function
set(this.Gui.Window, 'CloseRequestFcn', @this.closeFigureCallback);

%The main vertical box. The four main panes of the GUI are stacked in the
%box. We create these four boxes first so that we do not need to redraw
%them later
this.Gui.MainVbox=uix.VBox('Parent',this.Gui.Window,'BackgroundColor',rgb_white);

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

%Sets the heights and minimum heights of the five vertical boxes. -1 means
%it resizes with the window
if enable_save_panel
    %Creates the HBox for saving parameters
    this.Gui.SaveHbox=uix.HBox('Parent', this.Gui.MainVbox,...
        'BackgroundColor',rgb_white);
end

%Creates the HBox for the fitting parameters
this.Gui.FitHbox=uix.HBox('Parent',this.Gui.MainVbox,'BackgroundColor',...
    rgb_white);

if enable_save_panel
    set(this.Gui.MainVbox,'Heights',[title_h,-1,userpanel_h,savebox_h,slider_h],...
        'MinimumHeights',[title_h,equation_h,userpanel_h,savebox_h,slider_h]);
else
    set(this.Gui.MainVbox,'Heights',[title_h,-1,userpanel_h,slider_h],...
        'MinimumHeights',[title_h,equation_h,userpanel_h,slider_h]);
end

%Here we create the fit panel in the GUI.
this.Gui.FitPanel=uix.BoxPanel( 'Parent', this.Gui.UserHbox,...
    'Padding',0,'BackgroundColor', rgb_white,...
    'Title','Fit Panel','TitleColor',rgb_blue);
%Here we create the panel for the useful parameters
this.Gui.UserPanel=uix.BoxPanel( 'Parent', this.Gui.UserHbox,...
    'Padding',0,'BackgroundColor', 'w',...
    'Title','Calculated parameters','TitleColor',rgb_blue);
%Sets the widths of the above
set(this.Gui.UserHbox,'Widths',[-1,-2],'MinimumWidths',[0,375]);

%This makes the buttons that go inside the FitPanel
this.Gui.FitVbox=uix.VBox('Parent',this.Gui.FitPanel,'BackgroundColor',...
    rgb_white);
%Creates the button for analysis inside the VBox
this.Gui.AnalyzeButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Analyze', ...
    'Callback', @this.analyzeCallback);
%Creates button for generating new initial parameters
this.Gui.InitButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w',...
    'String','Generate initial parameters', ...
    'Callback', @this.initParamCallback);
%Creates button for clearing fits
this.Gui.ClearButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Clear fit', ...
    'Callback', @this.clearFitCallback);
%Button for triggering NewAcceptedFit event
this.Gui.AcceptFitButton=uicontrol('Parent',this.Gui.FitVbox,...
    'style','pushbutton','Background','w','String','Accept fit', ...
    'Callback', @this.acceptFitCallback);
%Checkbox for enabling cursors
this.Gui.CursorsCheckbox=uicontrol('Parent',this.Gui.FitVbox,...
    'style','checkbox','Background','w','String', ...
    'Range selection cursors','Callback', @this.enableCursorsCallback);

set(this.Gui.FitVbox,...
    'Heights', button_h*ones(1,length(this.Gui.FitVbox.Children)));

%Fill the user panel with controls
createUserControls(this, 'field_hight', button_h, 'background_color', 'w');

if enable_save_panel
    %This creates the boxes for saving files and for specifying file saving
    %properties
    this.Gui.SavePanel=uix.BoxPanel( 'Parent', this.Gui.SaveHbox,...
        'Padding',0,'BackgroundColor', rgb_white,...
        'Title','Save Panel','TitleColor',rgb_blue);
    this.Gui.DirPanel=uix.BoxPanel('Parent',this.Gui.SaveHbox,...
        'Padding',0,'BackgroundColor',rgb_white,...
        'Title','Directory Panel','TitleColor',rgb_blue);

    set(this.Gui.SaveHbox,'Widths',[-1,-2],'MinimumWidths',[0,375]);

    %Here we create the buttons and edit boxes inside the save box
    this.Gui.SaveButtonBox=uix.VBox('Parent',this.Gui.SavePanel,...
        'BackgroundColor',rgb_white);
    this.Gui.DirHbox=uix.HBox('Parent',this.Gui.DirPanel,...
        'BackgroundColor',rgb_white);
    this.Gui.FileNameLabelBox=uix.VBox('Parent',this.Gui.DirHbox,...
        'BackgroundColor',rgb_white);
    this.Gui.FileNameBox=uix.VBox('Parent',this.Gui.DirHbox,...
        'BackgroundColor',rgb_white);
    set(this.Gui.DirHbox,'Widths',[-1,-2]);

    %Buttons for saving the fit and parameters
    this.Gui.SaveFitButton=uicontrol('Parent',this.Gui.SaveButtonBox,...
        'style','pushbutton','Background','w','String','Save Fit',...
        'Callback', @(hObject, eventdata) saveFitCallback(this, hObject, eventdata));
    set(this.Gui.SaveButtonBox,'Heights',button_h* ...
        ones(1,length(this.Gui.SaveButtonBox.Children)));

    %Labels for the edit boxes
    this.Gui.BaseDirLabel=annotation(this.Gui.FileNameLabelBox,...
        'textbox',[0.5,0.5,0.3,0.3],...
        'String','Save Directory','Units','Normalized',...
        'HorizontalAlignment','Left','VerticalAlignment','middle',...
        'FontSize',10,'BackgroundColor',rgb_white);
    this.Gui.SessionNameLabel=annotation(this.Gui.FileNameLabelBox,...
        'textbox',[0.5,0.5,0.3,0.3],...
        'String','Session Name','Units','Normalized',...
        'HorizontalAlignment','Left','VerticalAlignment','middle',...
        'FontSize',10,'BackgroundColor',rgb_white);
    this.Gui.FileNameLabel=annotation(this.Gui.FileNameLabelBox,...
        'textbox',[0.5,0.5,0.3,0.3],...
        'String','File Name','Units','Normalized',...
        'HorizontalAlignment','Left','VerticalAlignment','middle',...
        'FontSize',10,'BackgroundColor',rgb_white);
    set(this.Gui.FileNameLabelBox,'Heights',button_h*ones(1,3));

    %Boxes for editing the path and filename
    this.Gui.BaseDir=uicontrol('Parent',this.Gui.FileNameBox,...
        'style','edit','HorizontalAlignment','Left',...
        'FontSize',10);
    this.Gui.SessionName=uicontrol('Parent',this.Gui.FileNameBox,...
        'style','edit','HorizontalAlignment','Left',...
        'FontSize',10);
    this.Gui.FileName=uicontrol('Parent',this.Gui.FileNameBox,...
        'style','edit','HorizontalAlignment','Left',...
        'FontSize',10);
    set(this.Gui.FileNameBox,'Heights',button_h*ones(1,3));
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
    %Generates a string for the limit boxes
    lim_str=sprintf('Lim_%s',this.fit_params{i});
    
    %Creates the vbox inside the panel that allows stacking
    this.Gui.(vbox_str) =uix.VBox( 'Parent', ...
        this.Gui.(panel_str{i}),'Padding',0,'BackgroundColor', 'w');
    
    %Generates edit box for fit parameters
    this.Gui.(edit_str)=uicontrol('Parent',this.Gui.(vbox_str),...
        'Style','edit','String',sprintf('%3.3e',this.param_vals(i)),...
        'FontSize',14,'HorizontalAlignment','Right',...
        'Position',[1,48,edit_width-4,30],'Units','Pixels', ...
        'Callback', createParamFieldEditedCallback(this, i));
    
    %Sets up HBox for the lower and upper limits
    this.Gui.(lim_str)=uix.HBox('Parent',this.Gui.(vbox_str),...
        'Padding',0,'BackgroundColor','w');
    
    %Generates edit box for limits
    this.Gui.([lim_str,'_lower'])=uicontrol('Parent',this.Gui.(lim_str),...
        'Style','edit','String',sprintf('%3.3e',this.lim_lower(i)),...
        'FontSize',10,'HorizontalAlignment','Right',...
        'Position',[1,1,edit_width-4,30],'Units','Pixels', ...
        'Callback', createLowerLimEditCallback(this, i));
    
    this.Gui.([lim_str,'_upper'])=uicontrol('Parent',this.Gui.(lim_str),...
        'Style','edit','String',sprintf('%3.3e',this.lim_upper(i)),...
        'FontSize',10,'HorizontalAlignment','Right',...
        'Position',[1,1,edit_width-4,30],'Units','Pixels', ...
        'Callback', createLowerLimEditCallback(this, i));
    
    %Generates java-based slider. Looks nicer than MATLAB slider
    this.Gui.(slider_str)=uicomponent('Parent',this.Gui.(vbox_str),...
        'style','jslider','Value',50,'Orientation',0,...
        'MajorTickSpacing',20,'MinorTickSpacing',5,'Paintlabels',0,...
        'PaintTicks',1,'Background',java.awt.Color.white,...
        'pos',[1,-7,edit_width-4,55]);
    %Sets up callbacks for the slider
    this.Gui.([slider_str,'_callback'])=handle(this.Gui.(slider_str),...
        'CallbackProperties');
    %Note that this is triggered whenever the state changes, even if it is
    %programatically
    this.Gui.([slider_str,'_callback']).StateChangedCallback = ....
         createSliderStateChangedCallback(this, i);
    this.Gui.([slider_str,'_callback']).MouseReleasedCallback = ....
        createSliderMouseReleasedCallback(this, i);
    
    %Sets heights and minimum heights for the elements in the fit vbox
    set(this.Gui.(vbox_str),'Heights',[30,30,55],'MinimumHeights',[30,30,55])
end

%Makes all the panels at the bottom visible at the same time
cellfun(@(x) set(this.Gui.(x),'Visible','on'),panel_str);

end