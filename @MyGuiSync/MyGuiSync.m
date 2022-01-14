% A mechanism to implement synchronization between parameters and GUI 
% elements in app-based GUIs

classdef MyGuiSync < handle
    
    properties (GetAccess = public, SetAccess = protected)
        Listeners = struct( ...
            'AppDeleted',       [], ...
            'KernelDeleted',    [] ...
            )
        
        % Link structures
        Links = struct( ...
            'reference',            {}, ... % reference to the link target
            'GuiElement',           {}, ... % graphics object      
            'gui_element_prop',     {}, ...
            'inputProcessingFcn',   {}, ... % applied after a value is 
                                        ... % inputed to GUI
            'outputProcessingFcn',  {}, ... % applied before a new value is
                                        ... % displayed in GUI 
            'getTargetFcn',         {}, ...
            'setTargetFcn',         {}, ...
            'Listener',             {}  ...  % PostSet listener (optional)        
            );
        
        % List of objects to be deleted when App is deleted
        cleanup_list = {}
    end
    
    properties (Access = protected)
        App
        updateGuiFcn
    end
    
    methods (Access = public)     
        function this = MyGuiSync(App, varargin)
            p = inputParser();
            
            addRequired(p, 'App', ...
                @(x)assert(isa(x, 'matlab.apps.AppBase'), ...
                'App must be a Matlab app.'));
            
            % Deletion of kernel object triggers the deletion of app
            addParameter(p, 'KernelObj', []);
            
            % Optional function, executed after an app parameter has been
            % updated (either externally of internally)
            addParameter(p, 'updateGuiFcn', [], ...
                @(x)isa(x, 'function_handle'));
            
            parse(p, App, varargin{:});
            
            this.updateGuiFcn = p.Results.updateGuiFcn;
            
            this.App = App;
            this.Listeners.AppDeleted = addlistener(App, ...
                'ObjectBeingDestroyed', @(~, ~)delete(this));
            
            % Kernel objects usually represent objects for which the app
            % provides user interface. Kernel objects are deleted with 
            % the app and the app is deleted if a kernel object is.
            if ~isempty(p.Results.KernelObj)
                if iscell(p.Results.KernelObj)
                    
                    % A cell containing the list kernel objects is supplied
                    cellfun(this.addKernelObj, p.Results.KernelObj);
                else
                    
                    % A single kernel object is supplied
                    addKernelObj(this, p.Results.KernelObj);
                end
            end
        end
        
        function delete(this)
            
            % Delete generic listeners
            try
                lnames = fieldnames(this.Listeners);
                for i = 1:length(lnames)
                    try
                        delete(this.Listeners.(lnames{i}));
                    catch
                        fprintf(['Could not delete the listener to ' ...
                            '''%s'' event.\n'], lnames{i})
                    end
                end
            catch
                fprintf('Could not delete listeners.\n');
            end
            
            % Delete link listeners
            for i = 1:length(this.Links)
                try
                    delete(this.Links(i).Listener);
                catch ME
                    warning(['Could not delete listener for a GUI ' ...
                        'link. Error: ' ME.message])
                end
            end
            
            % Delete the content of cleanup list
            for i = 1:length(this.cleanup_list)
                Obj = this.cleanup_list{i};
                try
                    if isa(Obj, 'timer')
                        
                        % Stop if object is a timer
                        try
                            stop(Obj);
                        catch
                        end
                    end
                    
                    % Check if the object has an appropriate delete method. 
                    % This is a safety measure to never delete a file by 
                    % accident.
                    if ismethod(Obj, 'delete')
                        delete(Obj);
                    else
                        fprintf(['Object of class ''%s'' ' ...
                            'does not have ''delete'' method.\n'], ...
                            class(Obj))
                    end
                catch
                    fprintf(['Could not delete an object of class ' ...
                        '''%s'' from the cleanup list.\n'], class(Obj))
                end
            end
        end
        
        % Establish a correspondence between the value of a GUI element and
        % some other property of the app
        % 
        % Elem      - graphics object 
        % prop_ref  - reference to a content of app, e.g. 'var1.subprop(3)' 
        function addLink(this, Elem, prop_ref, varargin)
            
            % Parse function inputs
            p = inputParser();
            p.KeepUnmatched = true;
            
            % The decision whether to create ValueChangedFcn and  
            % a PostSet callback is made automatically by this function, 
            % but the parameters below enforce these functions to be *not*
            % created.
            addParameter(p, 'create_elem_callback', true, @islogical);
            addParameter(p, 'event_update', true, @islogical);
            
            % Option, relevent when Elem is a menu and its chldren items
            % represent mutually exclusive multiple choices for the value 
            % of reference
            addParameter(p, 'submenu_choices', {}, @iscell);
            
            parse(p, varargin{:});
            
            % Make the list of unmatched name-value pairs for subroutine 
            sub_varargin = struct2namevalue(p.Unmatched);
            
            if strcmpi(Elem.Type, 'uimenu') && ...
                    ~ismember('submenu_choices', p.UsingDefaults)
                
                % The children of menu item represent multiple choices,
                % create separate links for all of them
                
                choises = p.Results.submenu_choices;
                assert(length(choises) == length(Elem.Children), ...
                    ['The length of the list of supplied multiple ' ...
                    'choices must be the same as the number of menu ' ...
                    'children.'])
                
                for i = 1:length(Elem.Children)
                    addLink(this, Elem.Children(i), prop_ref, ...
                        'outputProcessingFcn', ...
                            @(x)isequal(x, choises{i}), ...
                        'inputProcessingFcn', @(x)choises{i});
                end
                
                return
            end
            
            % Find the handle object which the end property belongs to, 
            % the end property name and, possibly, further subscripts 
            [Hobj, hobj_prop, RelSubs] = parseReference(this, prop_ref);
            
            % Check if the specified target is accessible for reading
            try
                if isempty(RelSubs)
                    Hobj.(hobj_prop);
                else
                    subsref(Hobj.(hobj_prop), RelSubs);
                end
            catch 
                disp(['Property referenced by ' prop_ref ...
                    ' is not accessible, the corresponding GUI ' ...
                    'element will be not linked and will be disabled.'])
                Elem.Enable = 'off';
                return
            end
            
            % Create the basis of link structure (everything except for 
            % set/get functions)
            Link = createLinkBase(this, Elem, prop_ref, sub_varargin{:});
            
            % Do additional link processing in the case of 
            % MyInstrument commands
            if isa(Hobj, 'MyInstrument') && ...
                    ismember(hobj_prop, Hobj.command_names)
                Link = extendMyInstrumentLink(this, Link, Hobj, hobj_prop);
            end
            
            % Assign the function that returns the value of reference
            Link.getTargetFcn = createGetTargetFcn(this, Hobj, ...
                hobj_prop, RelSubs);
            
            % Check if ValueChanged or another callback needs to be created
            elem_prop = Link.gui_element_prop;
            
            cb_name = findElemCallbackType(this, Elem, elem_prop, ...
                Hobj, hobj_prop);
            
            if p.Results.create_elem_callback && ~isempty(cb_name)
                
                % Assign the function that sets new value to reference
                Link.setTargetFcn = createSetTargetFcn(this, Hobj, ...
                    hobj_prop, RelSubs);
                
                switch cb_name
                    case 'ValueChangedFcn'
                        Elem.ValueChangedFcn = ...
                            createValueChangedCallback(this, Link);
                    case 'MenuSelectedFcn'
                        Elem.MenuSelectedFcn = ...
                            createMenuSelectedCallback(this, Link);
                    otherwise
                        error('Unknown callback name %s', cb_name)
                end
            end
            
            % Attempt creating a callback to PostSet event for the target 
            % property. If such callback is not created, the link needs to 
            % be updated manually.
            if p.Results.event_update
                try
                    Link.Listener = addlistener(Hobj, hobj_prop, ...
                        'PostSet', createPostSetCallback(this, Link));
                catch
                    Link.Listener = event.proplistener.empty();
                end
            end
            
            % Store the link structure
            ind = length(this.Links)+1;
            this.Links(ind) = Link;
            
            % Update the value of GUI element
            updateElementByIndex(this, ind);
        end

        % Change link reference for a given element or update the functions 
        % that get and set the value of the existing reference. 
        function reLink(this, Elem, prop_ref)
            
            % Find the index of link structure corresponding to Elem
            ind = ([this.Links.GuiElement] == Elem);
            ind = find(ind, 1);
            
            if isempty(ind)
                return
            end
            
            if ~exist('prop_ref', 'var')
                
                % If the reference is not supplied, update existing
                prop_ref = this.Links(ind).reference;
            end
            
            this.Links(ind).reference = prop_ref;
            
            if ~isempty(this.Links(ind).Listener)
                
                % Delete and clear the existing listener
                delete(this.Links(ind).Listener);
                this.Links(ind).Listener = [];
            end
            
            [Hobj, hobj_prop, RelSubs] = parseReference(this, prop_ref);
            
            this.Links(ind).getTargetFcn = createGetTargetFcn(this, ...
                Hobj, hobj_prop, RelSubs);
            
            if ~isempty(this.Links(ind).setTargetFcn)
                
                % Create a new ValueChanged callback 
                this.Links(ind).setTargetFcn = createSetTargetFcn(this, ...
                    Hobj, hobj_prop, RelSubs);
                
                this.Links(ind).GuiElement.ValueChangedFcn = ...
                    createValueChangedCallback(this, this.Links(ind));
            end
            
            % Attempt creating a new listener
            try
                this.Links(ind).Listener = addlistener(Hobj, hobj_prop, ...
                    'PostSet', createPostSetCallback(this, ...
                    this.Links(ind)));
            catch
                this.Links(ind).Listener = event.proplistener.empty();
            end
                
            % Update the value of GUI element according to the new
            % reference
            updateElementByIndex(this, ind);
        end
        
        function updateAll(this)
            for i = 1:length(this.Links)
                
                % Only update those elements for which listeners do not
                % exist
                if isempty(this.Links(i).Listener)
                    updateElementByIndex(this, i);
                end
            end
            
            % Optionally execute the update function defined within the App
            if ~isempty(this.updateGuiFcn)
                this.updateGuiFcn();
            end
        end
        
        % Update the value of one linked GUI element.
        function updateElement(this, Elem) 
            ind = ([this.Links.GuiElement] == Elem);
            ind = find(ind);
            
            if isempty(ind)
                warning('No link found for the GUI element below.');
                disp(Elem);
                
                return
            elseif length(ind) > 1
                warning('Multiple links found for the GUI element below.');
                disp(Elem);
                
                return
            end
            
            updateElementByIndex(this, ind);
        end
        
        function addToCleanup(this, Obj)
            
            % Prepend the new object so that the objects which are added
            % first would be deleted last
            this.cleanup_list = [{Obj}, this.cleanup_list];
        end
        
        % Remove an object from the cleanup list. The main usage of this
        % function is to provide a way to close GUI without deleting 
        % the kernel object 
        function removeFromCleanup(this, Obj)
            ind = cellfun(@(x)isequal(x, Obj), this.cleanup_list);
            this.cleanup_list(ind) = [];
        end
    end
       
    methods (Access = protected)  
        function addKernelObj(this, KernelObj)
            assert( ...
                ismember('ObjectBeingDestroyed', events(KernelObj)), ...
                ['Object must define ''ObjectBeingDestroyed'' event ' ...
                'to be an app kernel.'])

            addToCleanup(this, KernelObj);

            this.Listeners.KernelDeleted = addlistener(KernelObj,...
                'ObjectBeingDestroyed', @this.kernelDeletedCallback);
        end
        
        function kernelDeletedCallback(this, ~, ~)
            
            % Switch off the AppBeingDeleted callback in order to prevent
            % an infinite loop
            this.Listeners.AppDeleted.Enabled = false;
            
            % Delete app by closing its figure
            closeApp(this.App);
            delete(this);
        end
        
        function f = createPostSetCallback(this, Link)
            function postSetCallback(~,~)
                val = Link.getTargetFcn();
                
                if ~isempty(Link.outputProcessingFcn)
                    val = Link.outputProcessingFcn(val);
                end
                
                setIfChanged(Link.GuiElement, Link.gui_element_prop, val);

                % Optionally execute the update function defined within 
                % the App
                if ~isempty(this.updateGuiFcn)
                    this.updateGuiFcn();
                end
            end
            
            f = @postSetCallback;
        end
        
        % Callback that is assigned to graphics elements as ValueChangedFcn
        function f = createValueChangedCallback(this, Link)
            function valueChangedCallback(~, ~)           
                val = Link.GuiElement.Value;

                if ~isempty(Link.inputProcessingFcn)
                    val = Link.inputProcessingFcn(val);
                end

                if ~isempty(Link.Listener)
                    
                    % Switch the listener off
                    Link.Listener.Enabled = false;
                    
                    % Set the value
                    Link.setTargetFcn(val);
                    
                    % Switch the listener on again
                    Link.Listener.Enabled = true;
                else
                    Link.setTargetFcn(val);
                end
                
                % Update non event based links
                updateAll(this);
            end
            
            f = @valueChangedCallback;
        end
        
        % MenuSelected callbacks are different from ValueChanged in that
        % the state needs to be toggled manually
        function f = createMenuSelectedCallback(this, Link)
            function menuSelectedCallback(~, ~)           
                
                % Toggle the menu state
                if strcmpi(Link.GuiElement.Checked, 'on')
                    Link.GuiElement.Checked = 'off';
                    val = 'off';
                else
                    Link.GuiElement.Checked = 'on';
                    val = 'on';
                end

                if ~isempty(Link.inputProcessingFcn)
                    val = Link.inputProcessingFcn(val);
                end
                
                if ~isempty(Link.Listener)
                    
                    % Switch the listener off
                    Link.Listener.Enabled = false;
                    
                    % Set the value
                    Link.setTargetFcn(val);
                    
                    % Switch the listener on again
                    Link.Listener.Enabled = true;
                else
                    Link.setTargetFcn(val);
                end
                
                % Update non event based links
                updateAll(this);
            end
            
            f = @menuSelectedCallback;
        end
        
        function f = createGetTargetFcn(~, Obj, prop_name, S)
            function val = refProp()
                val = Obj.(prop_name);
            end
            
            function val = subsrefProp()
                val = subsref(Obj, S);
            end
            
            if isempty(S)
                
                % Faster way to access property
                f = @refProp;
            else
                
                % More general way to access property
                S = [substruct('.', prop_name), S];
                f = @subsrefProp;
            end
        end
        
        function f = createSetTargetFcn(~, Obj, prop_name, S)
            function assignProp(val)
                Obj.(prop_name) = val;
            end
            
            function subsasgnProp(val)
                Obj = subsasgn(Obj, S, val);
            end
            
            if isempty(S)
                
                % Faster way to assign property
                f = @assignProp;
            else
                
                % More general way to assign property
                S = [substruct('.', prop_name), S];
                f = @subsasgnProp;
            end
        end
        
        % Update the value of one linked GUI element given the index of
        % corresponding link
        function updateElementByIndex(this, ind)
            Link = this.Links(ind);
            
            val = Link.getTargetFcn();
            if ~isempty(Link.outputProcessingFcn)
                val = Link.outputProcessingFcn(val);
            end
            
            % Setting value to a matlab app elemen is time consuming, 
            % so first check if the value has actually changed
            setIfChanged(Link.GuiElement, Link.gui_element_prop, val);
        end
        
        %% Subroutines of addLink
        
        % Parse input and create the base of Link structure
        function Link = createLinkBase(this, Elem, prop_ref, varargin)
            
            % Parse function inputs
            p = inputParser();

            % GUI control element
            addRequired(p, 'Elem');

            % Target to which the value of GUI element will be linked 
            % relative to the App itself
            addRequired(p, 'prop_ref', @ischar);

            % Linked property of the GUI element (can be e.g. 'Color')
            addParameter(p, 'elem_prop', 'Value', @ischar);

            % If input_prescaler is given, the value assigned to the  
            % instrument propery is related to the value x displayed in 
            % GUI as x/input_presc.
            addParameter(p, 'input_prescaler', 1, @isnumeric);

            % Arbitrary processing functions can be specified for input and 
            % output. outputProcessingFcn is applied before assigning 
            % the new value to gui elements and inputProcessingFcn is 
            % applied before assigning to the new value to reference.
            addParameter(p, 'outputProcessingFcn', [], ...
                @(f)isa(f,'function_handle'));
            addParameter(p, 'inputProcessingFcn', [], ...
                @(f)isa(f,'function_handle'));
            
            % Parameters relevant for uilamps
            addParameter(p, 'lamp_on_color', MyAppColors.lampOn(), ...
                @iscolor);
            addParameter(p, 'lamp_off_color', MyAppColors.lampOff(), ...
                @iscolor);
            
            % Option which allows converting a binary choice into a logical
            % value
            addParameter(p, 'map', {}, @this.validateMapArg);

            parse(p, Elem, prop_ref, varargin{:});
            
            assert(all([this.Links.GuiElement] ~= p.Results.Elem), ...
                ['Another link for the same GUI element that is ' ...
                'attempted to be linked to ' prop_ref ' already exists.'])
            
            % Create a new link structure
            Link = struct( ...
                'reference',            prop_ref, ...
                'GuiElement',           p.Results.Elem, ...       
                'gui_element_prop',     p.Results.elem_prop, ...
                'inputProcessingFcn',   p.Results.inputProcessingFcn, ...
                'outputProcessingFcn',  p.Results.outputProcessingFcn, ...
                'getTargetFcn',         [], ...
                'setTargetFcn',         [], ...
                'Listener',             [] ...           
                );
            
            % Lamp indicators is a special case. It is often convenient to 
            % make a lamp indicate on/off state. If a lamp is being linked  
            % to a logical-type variable we therefore assign a dedicated 
            % OutputProcessingFcn that puts logical values in 
            % corresponcence with colors 
            if strcmpi(Elem.Type, 'uilamp')
                Link.gui_element_prop = 'Color';
                
                % Select between the on and off colors. 
                Link.outputProcessingFcn = @(x)select(x, ...
                    p.Results.lamp_on_color, p.Results.lamp_off_color);
                return
            end
            
            % Treat the special case of uimenus
            if strcmpi(Elem.Type, 'uimenu')
                Link.gui_element_prop = 'Checked';
            end
            
            if ~ismember('map', p.UsingDefaults)
                ref_vals = p.Results.map{1};
                gui_vals = p.Results.map{2};
                
                % Assign input and output processing functions that convert
                % a logical value into one of the options and back
                Link.inputProcessingFcn = @(x)select( ...
                    isequal(x, gui_vals{1}), ref_vals{:});
                Link.outputProcessingFcn = @(x)select( ...
                    isequal(x, ref_vals{1}), gui_vals{:});
            end

            % Simple scaling is a special case of value processing
            % functions.
            if ~ismember('input_prescaler', p.UsingDefaults)
                if isempty(Link.inputProcessingFcn) && ...
                        isempty(Link.outputProcessingFcn)
                    
                    Link.inputProcessingFcn = ...
                        @(x) (x/p.Results.input_prescaler);
                    Link.outputProcessingFcn = ...
                        @(x) (x*p.Results.input_prescaler);
                else
                    warning(['input_prescaler is ignored for target ' ...
                        prop_ref 'as inputProcessingFcn or ' ...
                        'outputProcessingFcn has been already ' ...
                        'assigned instead.']);
                end
            end
        end
        
        function Link = extendMyInstrumentLink(~, Link, Instrument, tag)
            Cmd = Instrument.CommandList.(tag);
            
            % If supplied command does not have read permission, issue a 
            % warning.
            if isempty(Cmd.readFcn)
                fprintf('Instrument property ''%s'' is nor readable\n', ...
                    tag);
                
                % Try switching the color of the gui element to orange
                try
                    Link.GuiElement.BackgroundColor = MyAppColors.warning();
                catch
                    try
                        Link.GuiElement.FontColor = MyAppColors.warning();
                    catch
                    end
                end
            end

            % Generate Items and ItemsData for dropdown menues if they were
            % not initialized manually
            if isequal(Link.GuiElement.Type, 'uidropdown') && ...
                    isempty(Link.GuiElement.ItemsData)
                
                str_value_list = cell(length(Cmd.value_list), 1);
                    
                for i=1:length(Cmd.value_list)
                    if ischar(Cmd.value_list{i})

                        % Capitalized displayed names for beauty
                        str = Cmd.value_list{i};
                        str_value_list{i} = [upper(str(1)), ...
                            lower(str(2:end))];
                    else

                        % Items in a dropdown should be strings
                        str_value_list{i} = num2str(Cmd.value_list{i});
                    end
                end
                
                Link.GuiElement.Items = str_value_list;

                % Assign the list of unprocessed values as ItemsData
                Link.GuiElement.ItemsData = Cmd.value_list;
            end
            
            % Add tooltip
            if isprop(Link.GuiElement, 'Tooltip') && ...
                    isempty(Link.GuiElement.Tooltip)
                Link.GuiElement.Tooltip = Cmd.info;
            end
        end
        
        % Decide what kind of callback (if any) needs to be created for 
        % the GUI element. Options: 'ValueChangedFcn', 'MenuSelectedFcn' 
        function callback_name = findElemCallbackType(~, ...
                Elem, elem_prop, Hobj, hobj_prop)
            
            % Check the reference object property attributes
            Mp = findprop(Hobj, hobj_prop);
            prop_write_accessible = strcmpi(Mp.SetAccess,'public') && ...
                (~Mp.Constant) && (~Mp.Abstract);
            
            % Check if the GUI element enabled and editable
            try
                gui_element_editable = strcmpi(Elem.Enable, 'on');
            catch
                gui_element_editable = true;
            end
            
            % A check for editability is only meaningful for uieditfieds. 
            % Drop-downs also have 'Editable' property, but it corresponds 
            % to the editability of elements and should not have an effect 
            % on assigning callbacks.
            if (strcmpi(Elem.Type, 'uinumericeditfield') || ...
                    strcmpi(Elem.Type, 'uieditfield')) ...
                    && strcmpi(Elem.Editable, 'off')
                gui_element_editable = false;
            end
            
            if ~(prop_write_accessible && gui_element_editable)
                callback_name = '';
                return
            end
            
            % Do not create a new callback if one already exists (typically 
            % it means that a callback was manually defined in AppDesigner)
            if strcmp(elem_prop, 'Value') && ...
                    isprop(Elem, 'ValueChangedFcn') && ...
                    isempty(Elem.ValueChangedFcn)
                
                % This is the most typical type of callback 
                callback_name = 'ValueChangedFcn';
            elseif strcmpi(Elem.Type, 'uimenu') && ...
                    strcmp(elem_prop, 'Checked') && ...
                    isempty(Elem.MenuSelectedFcn)
                
                callback_name = 'MenuSelectedFcn';
            else
                callback_name = '';
            end
        end
        
        % Extract the top-most handle object in the reference, the end
        % property name and any further subreference
        function [Hobj, prop_name, Subs] = parseReference(this, prop_ref)
            
            % Make sure the reference starts with a dot and convert to
            % subreference structure
            if prop_ref(1)~='.'
                PropSubs = str2substruct(['.', prop_ref]);
            else
                PropSubs = str2substruct(prop_ref);
            end
            
            % Find the handle object to which the end property belongs as
            % well as the end property name
            Hobj = this.App;
            
            Subs = PropSubs;     % Subreference relative to Hobj.(prop)
            prop_name = PropSubs(1).subs;
            
            for i=1:length(PropSubs)-1
                testvar = subsref(this.App, PropSubs(1:end-i));
                if isa(testvar, 'handle')
                    Hobj = testvar;
 
                    Subs = PropSubs(end-i+2:end);
                    prop_name = PropSubs(end-i+1).subs;
                    
                    break
                end
            end
        end
        
        % Validate the value of 'map' optional argument in createLinkBase
        function validateMapArg(~, arg)
            try
                is_map_arg = iscell(arg) && length(arg)==2 && ...
                    length(arg{1})==2 && length(arg{2})==2; 
            catch
                is_map_arg = false;
            end
            
            assert(is_map_arg, ['The value must be a cell of the form ' ...
                '{{reference value 1, reference value 2}, ' ...
                '{GUI dispaly value 1, GUI dispaly value 2}}.'])
        end
    end
end

