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
    
    % A property of the GUI element that is updated according to the value
    % under prop_tag can be other than 'Value' (e.g. 'Color' in the case of
    % a lamp indicator)
    addParameter(p,'elem_prop','Value',@ischar);
    
    % If input_presc is given, the value assigned to the instrument propery  
    % is related to the value x displayed in GUI as x/input_presc.
    addParameter(p,'input_presc',1,@isnumeric);
    
    % Arbitrary processing functions can be specified for input and output.
    % out_proc_fcn is applied to values before assigning them to gui
    % elements and in_proc_fcn is applied before assigning
    % to the linked properties
    addParameter(p,'out_proc_fcn',@(x)x,@(f)isa(f,'function_handle'));
    addParameter(p,'in_proc_fcn',@(x)x,@(f)isa(f,'function_handle'));
    
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
        target_val=subsref(app, PropSubref);
    catch
        disp(['Property corresponding to tag ',prop_tag,...
            ' is not accessible, element is not linked and disabled.'])
        elem.Enable='off';
        return
    end
    
    % Check if the tag refers to a property of an object, which also helps
    % to determine is callback is to be created
    if (length(PropSubref)>1) && isequal(PropSubref(end).type,'.')
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
            try
                % indprop may sometimes throw errors, especially on Matlab 
                % below 2018a, therefore use try-catch
                mp = findprop(Obj, tag);
                % Newer create callbacks for the properties with
                % attributes listed below, as those cannot be set
                if mp.Constant||mp.Abstract||~strcmpi(mp.SetAccess,'public')
                    create_callback=false;
                end
            catch
            end
        end
    else
        is_cmd=false;
    end
    
    % Check if the gui element is editable - if it is not, then a callback 
    % is not assigned. This is only meaningful for uieditfieds. Drop-downs
    % also have 'Editable' property, but it corresponds to the editability
    % of elements and does not have an effect on assigning callback.
    if (strcmpi(elem.Type, 'uinumericeditfield') || ...
            strcmpi(elem.Type, 'uieditfield')) ...
            && strcmpi(elem.Editable, 'off')
        create_callback=false;
    end
    
    % If the gui element is disabled callback is not assigned
    if isprop(elem, 'Enable') && strcmpi(elem.Enable, 'off')
        create_callback=false;
    end
    
    % If create_callback is true and the element does not already have 
    % a callback, assign genericValueChanged as ValueChangedFcn
    if create_callback && isprop(elem, 'ValueChangedFcn') && ...
            isempty(elem.ValueChangedFcn)
        % A public createGenericCallback method needs to intorduced in the
        % app, as officially Matlab apps do not support an automatic
        % callback assignment (as of the version of Matlab 2018a)
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
    
    % A step relevant for lamp indicators. It is often convenient to have a
    % lamp as an indicator of on/off state. If a lamp is being linked to a 
    % logical-type variable we therefore assign OutputProcessingFcn puts 
    % logical values in corresponcence with colors 
    if strcmpi(elem.Type, 'uilamp') && islogical(target_val)
        % The property of lamp that is to be updated by updateGui is not
        % Value but Color
        elem.UserData.elem_prop='Color';
        % Select between the default on and off colors. Different colors
        % can be indicated by explicitly setting OutputProcessingFcn that
        % will overwrite the one assigned here.
        elem.UserData.OutputProcessingFcn = ...
            @(x)select(x, MyAppColors.lampOn(), MyAppColors.lampOff());
    end

    % If a prescaler, input processing function or output processing  
    % function is specified, store it in UserData of the element
    if p.Results.input_presc ~= 1
        elem.UserData.InputPrescaler = p.Results.input_presc;
    end
    if ~ismember('in_proc_fcn',p.UsingDefaults)
        elem.UserData.InputProcessingFcn = p.Results.in_proc_fcn;
    end
    if ~ismember('out_proc_fcn',p.UsingDefaults)
        elem.UserData.OutputProcessingFcn = p.Results.out_proc_fcn;
    end
    
    if ~ismember('elem_prop',p.UsingDefaults)
        elem.UserData.elem_prop = p.Results.out_proc_fcn;
    end
    
    %% Linking
    
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
            try
                elem.BackgroundColor = MyAppColors.warning;
            catch
                try
                    elem.FontColor = MyAppColors.warning;
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

