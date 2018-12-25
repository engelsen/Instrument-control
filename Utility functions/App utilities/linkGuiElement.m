% Using app.linked_elem_list, create correspondence between app 
% properties or sub-properties and Value fields of control elements.
% The elements added to linked_elem_list are updated when updateGui is
% called.
% This function is applicable to any app sub-properties, but also contains 
% extended functionality in case the tag corresponds to a command of
% MyScpiInstrument.
% By default a callback to the ValueChanged event of the gui element is
% assigned, for which the app needs to have createGenericCallback method

function linkGuiElement(app, elem, prop_tag, varargin)
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
    addParameter(p,'create_callback',true,@islogical);
    % For drop-down menues initializes entries automatically based on the 
    % list of values. Ignored for all the other control elements. 
    addParameter(p,'init_val_list',false,@islogical);
    parse(p,elem,prop_tag,varargin{:});
    
    create_callback = p.Results.create_callback;
    
    if isempty(prop_tag)
        warning('''prop_tag'' is empty, element is not linked')
        return
    end
    
    % Make sure the property tag starts with a dot and convert to
    % subreference structure
    if prop_tag(1)~='.'
        PropSubref=str2substruct(['.',prop_tag]);
    else
        PropSubref=str2substruct(prop_tag);
    end
    
    % Check if the referenced property is accessible
    try
        subsref(app, PropSubref);
    catch
        disp(['Property corresponding to tag ',prop_tag,...
            ' is not accessible, element is not linked and disabled.'])
        elem.Enable='off';
        return
    end
    
    % Check if the tag refers to a property of an object
    if (length(PropSubref)>1) && PropSubref(end).type=='.'
        % Potential MyInstrument object
        Obj=subsref(app, PropSubref(1:end-1));
        % Potential command name
        tag=PropSubref(end).subs;
        % Check if the property corresponds to an instrument command
        try 
            is_cmd=ismember(tag, Obj.command_names);
        catch
            % If anything goes wrong in the previous block the prop is not
            % a command
            is_cmd=false;
        end
        if is_cmd
            % Object is an instrument.
            Instr=Obj;
            % Never create callbacks for read-only properties.
            if ~contains(Instr.CommandList.(tag).access,'w')
                create_callback=false;
            end
        % Then check if the tag corresponds to a simple object
        % property (and not to a structure field)
        elseif isprop(Obj, tag)
            mp = findprop(Obj, tag);
            % Newer create callbacks for the properties with
            % attributes listed below, as those cannot be set
            if mp.Constant||mp.Abstract||~strcmpi(mp.SetAccess,'public')
                create_callback=false;
            end
        end
    else
        is_cmd=false;
    end
    
    % If the create_callback is true, assign genericValueChanged as
    % callback
    if create_callback
        assert(ismethod(app,'createGenericCallback'), ['App needs to ',...
            'contain public createGenericCallback method to automatically'...
            'assign callbacks. Use ''create_callback'',false in order to '...
            'disable automatic callback']);
        elem.ValueChangedFcn = createGenericCallback(app);
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
    
    % The link is established by storing the subreference structure
    % in UserData and adding elem to the list of linked elements
    elem.UserData.LinkSubs = PropSubref;
    app.linked_elem_list = [app.linked_elem_list, elem];
    
    %% MyScpiInstrument-specific
    % The remaining code provides extended functionality for linking to 
    % commands of MyScpiInstrument
    
    if is_cmd
        % If supplied command does not have read permission, issue warning.
        if ~contains(Instr.CommandList.(tag).access,'r')
            fprintf(['Instrument command ''%s'' does not have read permission,\n',...
                'corresponding gui element will not be automatically ',...
                'syncronized\n'],tag);
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

        % Auto initialization of entries, for dropdown menus only
        if p.Results.init_val_list && isequal(elem.Type, 'uidropdown')
            try
                cmd_val_list = Instr.CommandList.(tag).val_list;
                if all(cellfun(@ischar, cmd_val_list))
                    % If the command has only string values, get the list of
                    % values ignoring abbreviations
                    cmd_val_list = stdValueList(Instr, tag);
                    % Capitalized the displayed values
                    elem.Items = cellfun(@(x)[upper(x(1)),lower(x(2:end))],...
                        cmd_val_list,'UniformOutput',false);
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
                end
                % Assign raw values list as ItemsData
                elem.ItemsData = cmd_val_list;
            catch
                warning(['Could not automatically assign values',...
                    ' when linking ',tag,' property']);
            end
        end
    end
end

