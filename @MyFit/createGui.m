function createGui(this)

fit_name=[upper(this.fit_name(1)),this.fit_name(2:end)];

rgb_blue=[0.5843-0.4,0.8157-0.4,1];
rgb_white=[1,1,1];
%Name sets the title of the window, NumberTitle turns off the FigureN text
%that would otherwise be before the title, MenuBar is the menu normally on
%the figure, toolbar is the toolbar normally on the figure.
%HandleVisibility refers to whether gcf, gca etc will grab this figure.
this.Gui.Window = figure('Name', 'MyFit', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'Toolbar', 'none', 'HandleVisibility', 'off',...
    'Units','Pixels','Position',[500,500,100*length(this.fit_params),400]);

%The main vertical box. The four main panes of the GUI are stacked in the
%box.
this.Gui.MainVbox=uix.VBox('Parent',this.Gui.Window,'BackgroundColor','w');
%The title box
this.Gui.Title=uicontrol('Parent',this.Gui.MainVbox,'Style','text',...
    'String',fit_name,'Units','Normalized',...
    'FontSize',14,'FontWeight','bold','BackgroundColor','w');
%Displays the fitted equation
this.Gui.Title=annotation(this.Gui.MainVbox,'textbox',[0.5,0.5,0.3,0.3],...
    'String',this.fit_tex,...
    'Units','Normalized','Interpreter','LaTeX',...
    'HorizontalAlignment','center','VerticalAlignment','middle',...
    'FontSize',20,'BackgroundColor','w');
%Creates an HBox to put extracted parameters such as quality factor in
this.Gui.UserHbox=uix.HBox('Parent',this.Gui.MainVbox,'BackgroundColor',rgb_white);

%Insert Switch/case block here for different fits

%Creates the HBox for the fitting parameters
this.Gui.FitHbox=uix.HBox('Parent',this.Gui.MainVbox);

%Sets the heights and minimum heights of the four vertical boxes. -1 
set(this.Gui.MainVbox,'Heights',[40,-1,-1,100],'MinimumHeights',[40,80,50,100]);

%Loops over the fit parameters to create one adjustment panel for each one
for i=1:length(this.fit_params)
    %Generates the string for the panel handle
    panel_str=sprintf('panel_%s',this.fit_params{i});
    %Generates the string for the vbox handle
    vbox_str=sprintf('vbox_%s',this.fit_params{i});
    %Generates the string for the slider handle
    slider_str=sprintf('slider_%s',this.fit_params{i});
    %Generates string for edit panels
    edit_str=sprintf('edit_%s',this.fit_params{i});
    %Creates the panel
    this.Gui.(panel_str)=uix.BoxPanel( 'Parent', this.Gui.FitHbox ,...
        'Padding',0,'BackgroundColor', 'w',...
        'Title',this.fit_param_names{i},'TitleColor',rgb_blue);
    %Creates the vbox inside the panel that allows stacking 
    this.Gui.(sprintf('vbox_%s',this.fit_params{i})) =uix.VBox( 'Parent', ...
        this.Gui.(panel_str),'Padding',0,'BackgroundColor', 'w');
    %Generates edit box for fit parameters
    this.Gui.(edit_str)=uicontrol('Parent',this.Gui.(vbox_str),...
        'Style','edit','String','0','FontSize',14,...
        'Tag',edit_str,'Callback',@(hObject,eventdata) edit_Callback(this, hObject, eventdata));
    %Generates java-based slider. Looks nicer than MATLAB slider
    this.Gui.(sprintf('slider_%s',this.fit_params{i}))=...
        uicomponent('Parent',this.Gui.(vbox_str),'style',...
        'jslider','pos',[0,0,95,45],'Value',72,'Orientation',0,...
        'MajorTickSpacing',20,'MinorTickSpacing',10,...
        'Paintlabels',0,'PaintTicks',1,'Value',50,'Background',...
        java.awt.Color(rgb_white(1),rgb_white(2),rgb_white(3)));

    %Sets up callbacks for the slider
    this.Gui.([slider_str,'_callback'])=handle(this.Gui.(slider_str),...
        'CallbackProperties');
    this.Gui.([slider_str,'_callback']).StateChangedCallback = ....
        @(hObject, eventdata) slider_Callback(this,i,hObject,eventdata);
%         @(hjSlider,eventData) set(this.Gui.(sprintf('edit_%s',this.fit_params{i})),...
%         'String',(get(hjSlider,'Value')));
    %Sets heights and minimum heights for the elements in the fit vbox
    set(this.Gui.(vbox_str),'Heights',[25,55],'MinimumHeights',[25,55])
end
end