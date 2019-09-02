% Fill the user panel with control elements using the information in
% UserParamList

function createUserControls(this, varargin)
    p = inputParser();
    addParameter(p, 'background_color', 'w');
    addParameter(p, 'field_hight', 0);
    parse(p, varargin{:});

    bg_color = p.Results.background_color;
    field_h = p.Results.field_hight;

    % First, create the main hbox and two vboxes within it, for the display
    % of parameter labels and values, respectively.
    this.Gui.UserHbox = uix.HBox('Parent', this.Gui.UserPanel, ...
        'BackgroundColor', bg_color);
    this.Gui.UserParamNameVBox = uix.VBox('Parent', this.Gui.UserHbox, ...
        'BackgroundColor', bg_color);
    this.Gui.UserParamEditVBox = uix.VBox('Parent', this.Gui.UserHbox, ...
        'BackgroundColor', bg_color);
    set(this.Gui.UserHbox, 'Widths', [-2,-1]);

    param_names = fieldnames(this.UserParamList);

    for i=1:length(param_names)
        S = this.UserParamList.(param_names{i});
        
        % Create names for the label and edit field gui elements
        lcn = sprintf('%sLabel',param_names{i});
        vcn = sprintf('%sEdit',param_names{i});

        this.Gui.(lcn) = annotation(this.Gui.UserParamNameVBox, ...
            'textbox',              [0.5,0.5,0.3,0.3], ...
            'String',               S.title, ...
            'Units',                'Normalized', ...
            'HorizontalAlignment',  'Left', ...
            'VerticalAlignment',    'middle', ...
            'FontSize',             10, ...
            'BackgroundColor',      bg_color);
        
        this.Gui.(vcn) = uicontrol( ...
            'Parent',               this.Gui.UserParamEditVBox, ...
            'Style',                'edit', ...
            'HorizontalAlignment',  'Right', ...
            'FontSize',             10, ...
            'Enable',               S.editable, ...
            'String',               num2str(this.(param_names{i})));

        if S.editable
            this.Gui.(vcn).Callback = ...
                createUserParamCallback(this, param_names{i});
        end
        
        % Create a set method for the dynamic property corresponding to the
        % user parameter, which will update the value displayed in GUI if 
        % property value is changed programmatically.
        S.Metaprop.SetMethod = createSetUserParamFcn( ...
            param_names{i}, this.Gui.(vcn));
    end

    % Sets the heights of the edit boxes 
    set(this.Gui.UserParamNameVBox, ...
        'Heights', field_h*ones(1, length(param_names)));
    set(this.Gui.UserParamEditVBox, ...
        'Heights', field_h*ones(1, length(param_names)));
end

% Subroutine for the creation of dynamic set methods
function f = createSetUserParamFcn(param_name, GuiElement)
    function setUserParam(this, val)
        this.(param_name) = val;
        GuiElement.String = num2str(val);
    end

    f = @setUserParam;
end

