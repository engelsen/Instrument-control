% Start the Gui with specified instrument class
% Assign the instance name to the class variable and the instrument name to 
% the window
function genericInitGui(app, default_instr_class, interface, address, varargin)
    p=inputParser();
    % Ignore unmatched parameters
    p.KeepUnmatched = true;
    addParameter(p,'instance_name','',@ischar);
    addParameter(p,'instr_class','',@ischar);
    parse(p,varargin{:});
    
    % Assign the instance name (instance is gui+instrument)
    if isprop(app, 'instance_name')
        app.instance_name = p.Results.instance_name;
    else
        warning(['''instance_name'' property is absent in the ',...
            'gui class, the instance global variable will not ',...
            'be cleared on exit'])
    end
    
    % Connect to the instrument by using either instr_class or 
    % default_instr_class
    if ~ismember(p.UsingDefaults, 'instr_class')
        class = p.Results.instr_class;
    elseif isequal(interface,'instr_list')
        % load the InstrumentList structure
        InstrumentList = getLocalInstrList();
        % In this case 'address' is the instrument name in the list
        instr_name = address;
        if ~isfield(InstrumentList, instr_name)
            error('%s is not a field of InstrumentList', instr_name)
        end
        class = InstrumentList.(instr_name).control_class;
    else
        % The default class is Gui-specific, so need to set it manually
        class = default_instr_class;
    end
    app.Instr = feval(class, interface, address, varargin{:});
    readPropertyHedged(app.Instr,'all');
    
    % Display instrument's name if given
    if ~isempty(app.Instr.name)     
        fig_handle=findfigure(app);
        if ~isempty(fig_handle)
            fig_handle.Name=char(app.Instr.name);
        else
            warning('No UIFigure found to assign the name')
        end
    end
end
