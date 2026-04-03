function createGui(this, varargin)

p = inputParser();

%Parameter that tells the function if save panel should be created
addParameter(p, 'save_panel', true, @islogical);
parse(p, varargin{:});
enable_save_panel = p.Results.save_panel;

if ~isempty(this.fit_name)

    %Makes the fit name have the first letter capitalized
    fit_name = [upper(this.fit_name(1)), this.fit_name(2:end)];
else
    fit_name = '';
end

%% Calculate the dimensions of GUI panels

%Defines the colors for the Gui
rgb_blue  = [0.1843, 0.4157, 1];
rgb_white = [1, 1, 1];

%Width of the edit boxes in the GUI
edit_width = 140;

%Font sizes
font_title     = 18;  % Fit name at top
font_button    = 12;  % Buttons
font_param     = 16;  % Parameter value edit fields
font_limit     = 12;  % Limit edit fields
font_label     = 12;  % Labels (save panel, user params)
font_titlebar  = 12;  % Panel title bar text

%Height of buttons in GUI
button_h = 28;

%Height of colored panel title bars
title_bar_h = 22;

%Minimum height of the hboxes composing the gui.
title_h    = 45;
equation_h = 100;
fitbox_h   = 3 * button_h + title_bar_h;
savebox_h  = 105 + title_bar_h;
slider_h   = 145 + title_bar_h;

min_fig_width = 560;

%Finds the height in button heights of the user field panel.
n_user_pars = length(fieldnames(this.UserParamList));
if n_user_pars > 0
    userpanel_h = button_h * (n_user_pars + 1) + title_bar_h;
else
    userpanel_h = 0;
end

fig_h = title_h + equation_h + fitbox_h + slider_h + userpanel_h;
if enable_save_panel
    fig_h = fig_h + savebox_h;
end

%Sets a minimum width
if this.n_params < 4
    if this.n_params ~= 0
        edit_width = min_fig_width / this.n_params;
    else
        % Support the case of dummy fit with no parameters
        edit_width = min_fig_width;
    end
end
fig_width = edit_width * this.n_params;

%% Build row height list for the main vertical grid
% Order: title, equation (resizable), fitbox, [user panel], [save panel], sliders
row_heights = {title_h, '1x', fitbox_h};
if n_user_pars > 0
    row_heights{end+1} = userpanel_h;
end
if enable_save_panel
    row_heights{end+1} = savebox_h;
end
row_heights{end+1} = slider_h;

%% Create figure
%HandleVisibility prevents gcf/gca from grabbing this figure.
this.Gui.Window = uifigure('Name', class(this), 'HandleVisibility', 'off', ...
    'Position', [100, 100, fig_width, fig_h], ...
    'Color', rgb_white);

%Place the figure in the center of the screen
centerFigure(this.Gui.Window);

%Sets the close function (runs when x is pressed) to be class function
this.Gui.Window.CloseRequestFcn = @this.closeFigureCallback;

%% Main vertical grid
this.Gui.MainVbox = uigridlayout(this.Gui.Window, [length(row_heights), 1], ...
    'RowHeight', row_heights, ...
    'Padding', [0 0 0 0], 'RowSpacing', 0, ...
    'BackgroundColor', rgb_white);

%% Title
this.Gui.Title = uilabel(this.Gui.MainVbox, ...
    'Text', fit_name, ...
    'HorizontalAlignment', 'center', ...
    'FontSize', font_title, ...
    'FontWeight', 'bold');
this.Gui.Title.Layout.Row = 1;
this.Gui.Title.Layout.Column = 1;

%% Equation axes — displays the LaTeX fit formula
this.Gui.EquationAxes = uiaxes(this.Gui.MainVbox, ...
    'XTick', [], 'YTick', [], ...
    'Color', rgb_white);
this.Gui.EquationAxes.Layout.Row = 2;
this.Gui.EquationAxes.Layout.Column = 1;
axis(this.Gui.EquationAxes, 'off');
xlim(this.Gui.EquationAxes, [0 1]);
ylim(this.Gui.EquationAxes, [0 1]);

this.Gui.EquationText = text(this.Gui.EquationAxes, 0.5, 0.5, this.fit_tex, ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 22);

%% Fit panel (row 3)
[this.Gui.FitPanel, fit_inner] = makeBoxPanel( ...
    this.Gui.MainVbox, 'Fit Panel', title_bar_h, font_titlebar, rgb_blue, rgb_white);
this.Gui.FitPanel.Layout.Row = 3;
this.Gui.FitPanel.Layout.Column = 1;

%Three-column inner grid: Analyze/Init | Clear/Accept | Cursors
this.Gui.FitInnerHbox = uigridlayout(fit_inner, [1, 3], ...
    'ColumnWidth', {'1x','1x','1x'}, ...
    'Padding', [4 4 4 4], 'ColumnSpacing', 4);
this.Gui.FitInnerHbox.Layout.Row = 2;
this.Gui.FitInnerHbox.Layout.Column = 1;

%Column 1: Analyze + Init params
this.Gui.FitVbox1 = uigridlayout(this.Gui.FitInnerHbox, [2, 1], ...
    'RowHeight', {button_h, button_h}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 4);
this.Gui.FitVbox1.Layout.Row = 1;
this.Gui.FitVbox1.Layout.Column = 1;

this.Gui.AnalyzeButton = uibutton(this.Gui.FitVbox1, ...
    'Text', 'Analyze', ...
    'FontSize', font_button, ...
    'ButtonPushedFcn', @this.analyzeCallback);
this.Gui.AnalyzeButton.Layout.Row = 1;
this.Gui.AnalyzeButton.Layout.Column = 1;

this.Gui.InitButton = uibutton(this.Gui.FitVbox1, ...
    'Text', 'Init params', ...
    'FontSize', font_button, ...
    'ButtonPushedFcn', @this.initParamCallback);
this.Gui.InitButton.Layout.Row = 2;
this.Gui.InitButton.Layout.Column = 1;

%Column 2: Clear fit + Accept fit
this.Gui.FitVbox2 = uigridlayout(this.Gui.FitInnerHbox, [2, 1], ...
    'RowHeight', {button_h, button_h}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 4);
this.Gui.FitVbox2.Layout.Row = 1;
this.Gui.FitVbox2.Layout.Column = 2;

this.Gui.ClearButton = uibutton(this.Gui.FitVbox2, ...
    'Text', 'Clear fit', ...
    'FontSize', font_button, ...
    'ButtonPushedFcn', @this.clearFitCallback);
this.Gui.ClearButton.Layout.Row = 1;
this.Gui.ClearButton.Layout.Column = 1;

this.Gui.AcceptFitButton = uibutton(this.Gui.FitVbox2, ...
    'Text', 'Accept fit', ...
    'FontSize', font_button, ...
    'ButtonPushedFcn', @this.acceptFitCallback);
this.Gui.AcceptFitButton.Layout.Row = 2;
this.Gui.AcceptFitButton.Layout.Column = 1;

%Column 3: Range cursors checkbox + Center cursors button
this.Gui.FitVbox3 = uigridlayout(this.Gui.FitInnerHbox, [2, 1], ...
    'RowHeight', {button_h, button_h}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 4);
this.Gui.FitVbox3.Layout.Row = 1;
this.Gui.FitVbox3.Layout.Column = 3;

this.Gui.CursorsCheckbox = uicheckbox(this.Gui.FitVbox3, ...
    'Text', 'Range cursors', ...
    'FontSize', font_button, ...
    'ValueChangedFcn', @this.enableCursorsCallback);
this.Gui.CursorsCheckbox.Layout.Row = 1;
this.Gui.CursorsCheckbox.Layout.Column = 1;

this.Gui.CenterCursorsButton = uibutton(this.Gui.FitVbox3, ...
    'Text', 'Center cursors', ...
    'FontSize', font_button, ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(~,~) centerCursors(this));
this.Gui.CenterCursorsButton.Layout.Row = 2;
this.Gui.CenterCursorsButton.Layout.Column = 1;

%% Remaining rows — track current row index
next_row = 4;

%% User parameters panel (conditional)
if n_user_pars > 0
    [this.Gui.UserPanel, user_inner] = makeBoxPanel( ...
        this.Gui.MainVbox, 'Calculated parameters', title_bar_h, font_titlebar, rgb_blue, rgb_white);
    this.Gui.UserPanel.Layout.Row = next_row;
    this.Gui.UserPanel.Layout.Column = 1;

    % Store the content container so createUserControls can find it
    this.Gui.UserPanelContent = user_inner;

    %Fill the user panel with controls
    createUserControls(this, 'field_height', button_h, 'font_size', font_label);
    next_row = next_row + 1;
end

%% Save panel (conditional)
if enable_save_panel
    %Two-column grid: save button panel (1x) | directory panel (2x)
    this.Gui.SaveHbox = uigridlayout(this.Gui.MainVbox, [1, 2], ...
        'ColumnWidth', {'1x', '2x'}, ...
        'Padding', [0 0 0 0], 'ColumnSpacing', 2, ...
        'BackgroundColor', rgb_white);
    this.Gui.SaveHbox.Layout.Row = next_row;
    this.Gui.SaveHbox.Layout.Column = 1;

    [this.Gui.SavePanel, save_inner] = makeBoxPanel( ...
        this.Gui.SaveHbox, 'Save Panel', title_bar_h, font_titlebar, rgb_blue, rgb_white);
    this.Gui.SavePanel.Layout.Row = 1;
    this.Gui.SavePanel.Layout.Column = 1;

    this.Gui.SaveButtonBox = uigridlayout(save_inner, [1, 1], ...
        'Padding', [6 6 6 6]);
    this.Gui.SaveButtonBox.Layout.Row = 2;
    this.Gui.SaveButtonBox.Layout.Column = 1;

    this.Gui.SaveFitButton = uibutton(this.Gui.SaveButtonBox, ...
        'Text', 'Save Fit', ...
        'FontSize', font_button, ...
        'ButtonPushedFcn', @(h,e) saveFitCallback(this, h, e));
    this.Gui.SaveFitButton.Layout.Row = 1;
    this.Gui.SaveFitButton.Layout.Column = 1;

    [this.Gui.DirPanel, dir_inner] = makeBoxPanel( ...
        this.Gui.SaveHbox, 'Directory Panel', title_bar_h, font_titlebar, rgb_blue, rgb_white);
    this.Gui.DirPanel.Layout.Row = 1;
    this.Gui.DirPanel.Layout.Column = 2;

    %Three-row, two-column grid: labels on left, edit fields on right
    this.Gui.DirHbox = uigridlayout(dir_inner, [3, 2], ...
        'ColumnWidth', {'1x', '2x'}, ...
        'RowHeight', {button_h, button_h, button_h}, ...
        'Padding', [6 6 6 6], 'RowSpacing', 4, 'ColumnSpacing', 6);
    this.Gui.DirHbox.Layout.Row = 2;
    this.Gui.DirHbox.Layout.Column = 1;

    this.Gui.BaseDirLabel = uilabel(this.Gui.DirHbox, ...
        'Text', 'Save Directory', 'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.BaseDirLabel.Layout.Row = 1;
    this.Gui.BaseDirLabel.Layout.Column = 1;

    this.Gui.SessionNameLabel = uilabel(this.Gui.DirHbox, ...
        'Text', 'Session Name', 'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.SessionNameLabel.Layout.Row = 2;
    this.Gui.SessionNameLabel.Layout.Column = 1;

    this.Gui.FileNameLabel = uilabel(this.Gui.DirHbox, ...
        'Text', 'File Name', 'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.FileNameLabel.Layout.Row = 3;
    this.Gui.FileNameLabel.Layout.Column = 1;

    this.Gui.BaseDir = uieditfield(this.Gui.DirHbox, 'text', ...
        'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.BaseDir.Layout.Row = 1;
    this.Gui.BaseDir.Layout.Column = 2;

    this.Gui.SessionName = uieditfield(this.Gui.DirHbox, 'text', ...
        'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.SessionName.Layout.Row = 2;
    this.Gui.SessionName.Layout.Column = 2;

    this.Gui.FileName = uieditfield(this.Gui.DirHbox, 'text', ...
        'HorizontalAlignment', 'left', 'FontSize', font_label);
    this.Gui.FileName.Layout.Row = 3;
    this.Gui.FileName.Layout.Column = 2;

    next_row = next_row + 1;
end

%% Slider panel — one uipanel per fit parameter
if this.n_params > 0
    this.Gui.SliderHbox = uigridlayout(this.Gui.MainVbox, [1, this.n_params], ...
        'ColumnWidth', repmat({'1x'}, 1, this.n_params), ...
        'Padding', [0 0 0 0], 'ColumnSpacing', 2, ...
        'BackgroundColor', rgb_white);
    this.Gui.SliderHbox.Layout.Row = next_row;
    this.Gui.SliderHbox.Layout.Column = 1;

    %We first make the panels to speed up the process. Otherwise everything
    %in the panel must be redrawn every time we make a new one.
    panel_str  = cell(1, this.n_params);
    inner_cell = cell(1, this.n_params);
    for i = 1:this.n_params
        panel_str{i} = sprintf('Panel_%s', this.fit_params{i});
        panel_title  = sprintf('%s (%s)', this.fit_param_names{i}, this.fit_params{i});
        [this.Gui.(panel_str{i}), inner_cell{i}] = makeBoxPanel( ...
            this.Gui.SliderHbox, panel_title, title_bar_h, font_titlebar, rgb_blue, rgb_white);
        this.Gui.(panel_str{i}).Layout.Row = 1;
        this.Gui.(panel_str{i}).Layout.Column = i;
        this.Gui.(panel_str{i}).Visible = 'off';
    end

    %Loops over number of parameters to create a fit panel for each one
    for i = 1:this.n_params
        vbox_str   = sprintf('Vbox_%s',   this.fit_params{i});
        slider_str = sprintf('Slider_%s', this.fit_params{i});
        edit_str   = sprintf('Edit_%s',   this.fit_params{i});
        lim_str    = sprintf('Lim_%s',    this.fit_params{i});

        %Three-row inner grid: value edit | limits | slider
        this.Gui.(vbox_str) = uigridlayout(inner_cell{i}, [3, 1], ...
            'RowHeight', {35, 30, 70}, ...
            'Padding', [4 6 4 6], 'RowSpacing', 4);
        this.Gui.(vbox_str).Layout.Row = 2;
        this.Gui.(vbox_str).Layout.Column = 1;

        %Edit box for the parameter value
        this.Gui.(edit_str) = uieditfield(this.Gui.(vbox_str), 'numeric', ...
            'Value', this.param_vals(i), ...
            'ValueDisplayFormat', '%3.3e', ...
            'HorizontalAlignment', 'right', ...
            'FontSize', font_param, ...
            'ValueChangedFcn', createParamFieldEditedCallback(this, i));
        this.Gui.(edit_str).Layout.Row = 1;
        this.Gui.(edit_str).Layout.Column = 1;

        %Two-column grid for lower and upper limits
        this.Gui.(lim_str) = uigridlayout(this.Gui.(vbox_str), [1, 2], ...
            'ColumnWidth', {'1x', '1x'}, ...
            'Padding', [0 0 0 0], 'ColumnSpacing', 2);
        this.Gui.(lim_str).Layout.Row = 2;
        this.Gui.(lim_str).Layout.Column = 1;

        this.Gui.([lim_str, '_lower']) = uieditfield(this.Gui.(lim_str), 'numeric', ...
            'Value', this.lim_lower(i), ...
            'ValueDisplayFormat', '%g', ...
            'HorizontalAlignment', 'right', ...
            'FontSize', font_limit, ...
            'Tooltip', 'Lower limit', ...
            'ValueChangedFcn', createLowerLimEditCallback(this, i));
        this.Gui.([lim_str, '_lower']).Layout.Row = 1;
        this.Gui.([lim_str, '_lower']).Layout.Column = 1;

        this.Gui.([lim_str, '_upper']) = uieditfield(this.Gui.(lim_str), 'numeric', ...
            'Value', this.lim_upper(i), ...
            'ValueDisplayFormat', '%g', ...
            'HorizontalAlignment', 'right', ...
            'FontSize', font_limit, ...
            'Tooltip', 'Upper limit', ...
            'ValueChangedFcn', createUpperLimEditCallback(this, i));
        this.Gui.([lim_str, '_upper']).Layout.Row = 1;
        this.Gui.([lim_str, '_upper']).Layout.Column = 2;

        %Slider — ValueChangingFcn fires continuously during drag,
        %ValueChangedFcn fires on release. No PostSet listener needed.
        this.Gui.(slider_str) = uislider(this.Gui.(vbox_str), ...
            'Limits', [0 100], 'Value', 50, ...
            'MajorTicks', [], 'MinorTicks', [], ...
            'ValueChangingFcn', createSliderDragCallback(this, i), ...
            'ValueChangedFcn',  createSliderCallback(this, i));
        this.Gui.(slider_str).Layout.Row = 3;
        this.Gui.(slider_str).Layout.Column = 1;
    end

    %Makes all the panels visible at the same time
    cellfun(@(x) set(this.Gui.(x), 'Visible', 'on'), panel_str);
end

end

%--------------------------------------------------------------------------
% Local helper: creates a uipanel with a colored title bar, mimicking the
% appearance of uix.BoxPanel. Returns the panel (set Layout on this) and
% the outer grid (add content as row 2 children with Layout.Row = 2).
%--------------------------------------------------------------------------
function [panel, outer] = makeBoxPanel(parent, title_str, title_bar_h, font_size, rgb_title, rgb_bg)
    panel = uipanel(parent, 'BackgroundColor', rgb_bg);
    outer = uigridlayout(panel, [2, 1], ...
        'RowHeight', {title_bar_h, '1x'}, ...
        'Padding', [0 0 0 0], 'RowSpacing', 0, ...
        'BackgroundColor', rgb_bg);
    lbl = uilabel(outer, ...
        'Text',               ['  ' title_str], ...
        'BackgroundColor',    rgb_title, ...
        'FontColor',          [1 1 1], ...
        'FontSize',           font_size, ...
        'HorizontalAlignment','left');
    lbl.Layout.Row = 1;
    lbl.Layout.Column = 1;
end
