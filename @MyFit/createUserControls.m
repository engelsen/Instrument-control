% Fill the user panel with control elements using the information in
% UserParamList

function createUserControls(this, varargin)
p = inputParser();
addParameter(p, 'field_height', 0);
addParameter(p, 'font_size', 12);
parse(p, varargin{:});

field_h = p.Results.field_height;
font_sz = p.Results.font_size;

param_names = fieldnames(this.UserParamList);
n = length(param_names);

% Two-column grid inside the user panel content area (row 2 of the title-bar grid)
this.Gui.UserInnerHbox = uigridlayout(this.Gui.UserPanelContent, [n, 2], ...
    'ColumnWidth', {'2x', '1x'}, ...
    'RowHeight', repmat({field_h}, 1, n), ...
    'Padding', [4 4 4 4], 'RowSpacing', 2, 'ColumnSpacing', 4);
this.Gui.UserInnerHbox.Layout.Row = 2;
this.Gui.UserInnerHbox.Layout.Column = 1;

for i = 1:n
    S = this.UserParamList.(param_names{i});

    % Names for the label and edit field GUI elements
    lcn = sprintf('%sLabel', param_names{i});
    vcn = sprintf('%sEdit',  param_names{i});

    this.Gui.(lcn) = uilabel(this.Gui.UserInnerHbox, ...
        'Text',               S.title, ...
        'Interpreter',        'html', ...
        'HorizontalAlignment','left', ...
        'FontSize',           10);
    this.Gui.(lcn).Layout.Row    = i;
    this.Gui.(lcn).Layout.Column = 1;

    init_val = this.(param_names{i});
    if isempty(init_val); init_val = 0; end
    this.Gui.(vcn) = uieditfield(this.Gui.UserInnerHbox, 'numeric', ...
        'Value',              init_val, ...
        'HorizontalAlignment','right', ...
        'FontSize',           font_sz, ...
        'Editable',           S.editable);
    this.Gui.(vcn).Layout.Row    = i;
    this.Gui.(vcn).Layout.Column = 2;

    if strcmp(S.editable, 'on')
        this.Gui.(vcn).ValueChangedFcn = ...
            createUserParamCallback(this, param_names{i});
    end

    % Set method on the dynamic property keeps the GUI field in sync when
    % the property is updated programmatically (e.g. after a fit).
    S.Metaprop.SetMethod = createSetUserParamFcn(param_names{i}, this.Gui.(vcn));
end

end

% Subroutine for the creation of dynamic set methods
function f = createSetUserParamFcn(param_name, GuiElement)
    function setUserParam(this, val)
        this.(param_name) = val;
        GuiElement.Value = val;
    end
    f = @setUserParam;
end
