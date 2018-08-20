% By using app.linked_elem_list, create a correspondence between a property
% of MyInstrument class (named prop_tag) and an element of the app gui
function linkGuiElementToCommand(app, elem, prop_tag, varargin)
    p=inputParser();
    % GUI control element
    addRequired(p,'elem');
    % Instrument command to be linked to the GUI element
    addRequired(p,'prop_tag',@ischar);
    % If input_presc is given, the value assigned to the instrument propery  
    % is related to the value x displayed in GUI as x/input_presc.
    addParameter(p,'input_presc',1,@isnumeric);
    % Add an arbitrary function for processing the value, read from the
    % device before outputting it. 
    addParameter(p,'out_proc_fcn',@(x)x,@(f)isa(f,'function_handle'));
    addParameter(p,'create_callback_fcn',@(x)0,@(f)isa(f,'function_handle'));
    % For drop-down menues initializes entries automatically based on the 
    % list of values. Ignored for all the other control elements. 
    addParameter(p,'init_val_list',false,@islogical);
    parse(p,elem,prop_tag,varargin{:});
    
    % If the property is not present in the instrument class, disable the
    % control
    if ~isprop(app.Instr, prop_tag)
        elem.Enable='off';
        elem.Visible='off';
        return
    end
    
    % If supplied command does not have read permission, issue warning.
    if ~ismember(prop_tag, app.Instr.read_commands)
        fprintf(['Instrument command ''%s'' does not have read permission,\n',...
            'corresponding gui element will not be automatically ',...
            'syncronized\n'],prop_tag);
        % Try switching color of the gui element to orange
        warning_color = [0.93, 0.69, 0.13];
        try
            elem.BackgroundColor = warning_color;
        catch
            try
                elem.FontColor = warning_color;
            catch
            end
        end
    end
    
    % The property-control link is established by assigning the tag
    % and adding the control to the list of linked elements
    elem.Tag = ['Instr.',prop_tag];
    app.linked_elem_list = [app.linked_elem_list, elem];

    % If the create_callback_fcn is set, assign it to the 
    % ValueChangedFcn which passes the field input to the instument 
    if ~ismember('create_callback_fcn',p.UsingDefaults)
        elem.ValueChangedFcn = feval(p.Results.create_callback_fcn);
        % Make callbacks non-interruptible for other callbacks
        % (but are still interruptible for timers)
        try
            elem.Interruptible = 'off';
            elem.BusyAction = 'cancel';
        catch
            warning('Could not make callback for %s non-interruptible',...
                prop_tag);
        end
    end

    % If prescaler is given, add it to the element as a new property
    if p.Results.input_presc ~= 1
        if isprop(elem, 'InputPrescaler')
            warning(['The InputPrescaler property already exists',...
                ' in the control element']);
        else
            addprop(elem,'InputPrescaler');
        end
        elem.InputPrescaler = p.Results.input_presc;
    end
    
    % Add an arbitrary function for output processing
    if ~ismember('out_proc_fcn',p.UsingDefaults)
        if isprop(elem, 'OutputProcessingFcn')
            warning(['The OutputProcessingFcn property already exists',...
                ' in the control element']);
        else
            addprop(elem,'OutputProcessingFcn');
        end
        elem.OutputProcessingFcn = p.Results.out_proc_fcn;
    end
    
    % Auto initialization of entries, for dropdown menus only
    if p.Results.init_val_list && isequal(elem.Type, 'uidropdown')
        try
            cmd_val_list = app.Instr.CommandList.(prop_tag).val_list;
            if all(cellfun(@ischar, cmd_val_list))
                % If the command has only string values, get the list of
                % values ignoring abbreviations
                cmd_val_list = stdValueList(app.Instr, prop_tag);
                elem.Items = lower(cmd_val_list);
                elem.ItemsData = cmd_val_list;
            else
                % Items in a dropdown should be strings, so convert if
                % necessary
                str_list=cell(length(cmd_val_list), 1);
                for i=1:length(cmd_val_list)
                    if ~ischar(cmd_val_list{i})
                        str_list{i}=num2str(cmd_val_list{i});
                    end
                end
                elem.Items = str_list;
                % Put raw values in ItemsData
                elem.ItemsData = cmd_val_list;
            end
        catch
            warning(['Could not automatically assign values',...
                ' when linking ',prop_tag,' property']);
        end
    end
end

