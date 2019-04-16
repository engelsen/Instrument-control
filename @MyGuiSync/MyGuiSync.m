% A mechanism to implement synchronization between parameters and GUI 
% elements in app-based GUIs

classdef MyGuiSync < handle
    
    properties (GetAccess = public, SetAccess = protected)
        Listeners = struct()
        
        % Link structures
        Links = struct( ...            
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
        createCallbackFcn
    end
    
    methods (Access = public)     
        function this = MyGuiSync(App, varargin)
            p = inputParser();
            
            addRequired(p, 'App', ...
                @(x)assert(isa(x, 'matlab.apps.AppBase'), ...
                'App must be a Matlab app.'));
            
            % Deletion of kernel object triggers the delition of app
            addParameter(p, 'KernelObj', [], @(x)assert( ...
                ismember('ObjectBeingDestroyed', events(x)), ...
                ['Object must define ''ObjectBeingDestroyed'' event ' ...
                'to be an app kernel.']));
            
            % Optional function, executed after an app parameter has been
            % updated (either externally of internally)
            addParameter(p, 'updateGuiFcn', [], ...
                @(x)isa(x, 'function_handle'));
            
            addParameter(p, 'createCallbackFcn', [], ...
                @(x)isa(x, 'function_handle'));
            
            parse(p, App, varargin{:});
            
            this.updateGuiFcn = p.Results.updateGuiFcn;
            this.createCallbackFcn = p.Results.createCallbackFcn;
            
            this.App = App;
            this.Listeners.AppDeleted = addlistener(App, ...
                'ObjectBeingDestroyed', @(~, ~)delete(this));
            
            if ~ismember('KernelObj', p.UsingDefaults)
                
                KernelObj = p.Results.KernelObj;
                addToCleanup(this, p.Results.KernelObj);
                
                this.Listeners.KernelObjDeleted = addlistener(KernelObj,...
                    'ObjectBeingDestroyed', @this.kernelDeletedCallback);
            end
        end
        
        
        function delete(this)
            
            % Delete generic listeners
            try
                lnames = fieldnames(this.Listeners);
                for i=1:length(lnames)
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
            for i=1:length(this.Links)
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
            addParameter(p, 'create_value_changed_fcn', true, @islogical);
            addParameter(p, 'event_update', true, @islogical);
            
            parse(p, varargin{:});
            
            % Make the list of unmatched name-value pairs for subroutine 
            sub_varargin = struct2namevalue(p.Unmatched);
            
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
            Link = makeLinkBase(this, Elem, prop_ref, sub_varargin{:});
            
            % Do additional link processing in the case of 
            % MyInstrument commands
            if isa(Hobj, 'MyInstrument') && ...
                    ismember(hobj_prop, Hobj.command_names)
                Link = extendMyInstrumentLink(this, Link, Hobj, hobj_prop);
            end
            
            % Assign the function that returns the value of reference
            Link.getTargetFcn = createGetTargetFcn(this, Hobj, ...
                hobj_prop, RelSubs);
            
            % Check if ValueChanged callback needs to be created
            elem_prop = Link.gui_element_prop;
            
            create_vcf = p.Results.create_value_changed_fcn && ...
                checkCreateVcf(this, Elem, elem_prop, Hobj, hobj_prop);
            
            if create_vcf
                
                % A public CreateCallback method needs to intorduced in the
                % app, as officially Matlab apps do not support external
                % callback assignment (as of the version of Matlab 2019a)
                assert(~isempty(this.createCallbackFcn), ...
                    ['Matlab app must define a public wrapper for ' ...
                    'createCallbackFcn in order for GuiSync to be able to ' ...
                    'automatically assign ValueChanged callbacks. ' ...
                    'The wrapper method must have signature ' ...
                    'publicCreateCallbackFcn(app, callbackFunction).']);
                
                % Assign the function that sets new value to reference
                Link.setTargetFcn = createSetTargetFcn(this, Hobj, ...
                    hobj_prop, RelSubs);
                
                Elem.ValueChangedFcn = createValueChangedCallback(this, ...
                    Link);
            end
            
            % Attempt creating a callback to PostSet event for the target 
            % property. If such callback is not created, the link needs to 
            % be updated manually.
            if p.Results.event_update
                try
                    Link.Listener = addlistener(Hobj, hobj_prop, ...
                        'PostSet', createPostSetCallback(this, Link));
                catch ME
                    warning(ME.message); 
                end
            end
            
            % Update the value of GUI element 
            updateLinkedElement(this, Link);
            
            % Store the link structure
            this.Links(end+1) = Link;
        end

        function reLink(this, Elem, prop_ref)
            
            % Find the link structure corresponding to Elem
            ind = find(arrayfun( @(x)isequal(x.GuiElement, Elem), ...
                this.Links));
            
            assert(length(ind) == 1, ['No or multiple existing links ' ...
                'found during a relinking attempt.'])
            
            % Delete and clear the existing listener
            if ~isempty(this.Links(ind).Listener)
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
            end
                
            % Update the value of GUI element according to the new
            % reference
            updateLinkedElement(this, this.Links(ind));
        end
        
        function updateLinkedElements(this)
            for i=1:length(this.Links)
                
                % Elements updated by callbacks should not be updated
                % manually
                if isempty(this.Links(i).Listener)
                    updateLinkedElement(this, this.Links(i));
                end
            end
        end
        
        % Update the value of one linked GUI element.
        % Arg2 can be a link structure or a GUI element for which the
        % corresponding link structure needs to be found.
        function updateLinkedElement(this, Arg2)
            if isstruct(Arg2)
                Link = Arg2;
                
                val = Link.getTargetFcn();
                if ~isempty(Link.outputProcessingFcn)
                    val = Link.outputProcessingFcn(val);
                end
                
                % Setting value to a matlab app elemen is time consuming, 
                % so first check if the value has actually changed
                setIfChanged(Link.GuiElement, Link.gui_element_prop, val);
            else
                Elem = Arg2;
                
                % Find the link structure corresponding to Elem
                ind = arrayfun( @(x)isequal(x.GuiElement, Elem), ...
                    this.Links);

                Link = this.Links(ind);

                if length(Link) == 1
                    updateLinkedElement(this, Link);
                elseif isempty(Link)
                    warning(['The value of GUI element below cannot ' ...
                        'be updated as no link for it is found.']);
                    disp(Elem);
                else
                    warning(['The value of GUI element below cannot ' ...
                        'be updated, multiple link structures exist.']);
                    disp(Elem);
                end
            end
        end
        
        function addToCleanup(this, Obj)
            this.cleanup_list{end+1} = Obj;
        end
    end
       
    methods (Access = protected)  
        function kernelDeletedCallback(this, ~, ~)
            
            % Switch off the AppBeingDeleted callback in order to prevent
            % an infinite loop
            this.Listeners.AppDeleted.Enabled = false;
            
            delete(this.App);
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

                Link.setTargetFcn(val);

                if isempty(Link.Listener)

                    % Update non event based links
                    updateLinkedElements(this);

                    % Optionally execute the update function defined within 
                    % the App
                    if ~isempty(this.updateGuiFcn)
                        this.updateGuiFcn();
                    end
                end
            end
            
            f = this.createCallbackFcn(@valueChangedCallback);
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
        
        %% Subroutines of addLink
        
        % Parse input and create the base of Link structure
        function Link = makeLinkBase(this, Elem, prop_ref, varargin)
            
            % Parse function inputs
            p = inputParser();

            % GUI control element
            addRequired(p, 'Elem');

            % Target to which the value of GUI element will be linked 
            % relative to the App itself
            addRequired(p, 'prop_ref', @ischar);

            % Linked property of the GUI element (can be e.g. 'Color')
            addParameter(p, 'elem_prop', 'Value', @ischar);

            % If input_prescaler is given, the value assigned to the instrument propery  
            % is related to the value x displayed in GUI as x/input_presc.
            addParameter(p, 'input_prescaler', 1, @isnumeric);

            % Arbitrary processing functions can be specified for input and output.
            % out_proc_fcn is applied to values before assigning them to gui
            % elements and in_proc_fcn is applied before assigning
            % to the linked properties
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
            addParameter(p, 'switch_between', {}, @(x)assert( ...
                iscell(x)&&length(x)==2, ['The value must be a cell ' ...
                'of the form {true_opt, false_opt}.']));

            parse(p, Elem, prop_ref, varargin{:});
            
            assert(~any( ...
                arrayfun(@(x) isequal(p.Results.Elem, x.GuiElement), ...
                this.Links)), ['Another link for the same GUI element ' ...
                'that is attempted to be linked to ' prop_ref ...
                ' already exists.'])
            
            % Create a new link structure
            Link = struct( ...
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
            end
            
            if ~ismember('switch_between', p.UsingDefaults)
                true_opt = p.Results.switch_between{1};
                false_opt = p.Results.switch_between{2};
                
                % Assign input and output processing functions that convert
                % a logical value into one of the options and back
                Link.inputProcessingFcn = @(x)select(x, true_opt, ...
                    false_opt);
                Link.outputProcessingFcn = @(x)isequal(x, true_opt);
            end

            % Simple scaling is a special case of value processing
            % functions.
            if ~ismember('input_prescaler', p.UsingDefaults)
                if isempty(Link.inputProcessingFcn) && ...
                        isempty(Link.outputProcessingFcn)
                    
                    Link.inputProcessingFcn = ...
                        @(x) (x/p.Result.input_prescaler);
                    Link.outputProcessingFcn = ...
                        @(x) (x*p.Result.input_prescaler);
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

            % Auto initialize the content of dropdown menues
            if isequal(Link.GuiElement.Type, 'uidropdown')
                if all(cellfun(@ischar, Cmd.value_list))

                    % Capitalized displayed names for beauty
                    Link.GuiElement.Items = cellfun( ...
                        @(x)[upper(x(1)),lower(x(2:end))],...
                        Cmd.value_list, 'UniformOutput', false);
                else

                    % Items in a dropdown should be strings, so convert if
                    % necessary
                    str_value_list = cell(length(Cmd.value_list), 1);
                    
                    for i=1:length(Cmd.value_list)
                        if ~ischar(Cmd.value_list{i})
                            str_value_list{i} = num2str(Cmd.value_list{i});
                        end
                    end
                    
                    Link.GuiElement.Items = str_value_list;
                end

                % Assign the list of unprocessed values as ItemsData
                Link.GuiElement.ItemsData = Cmd.value_list;
            end
            
            % Add tooltip
            if isprop(Link.GuiElement, 'Tooltip') && ...
                    isempty(Link.GuiElement.Tooltip)
                Link.GuiElement.Tooltip = Cmd.info;
            end
        end
        
        % Decide if getTargetFcn and, correpondingly, ValueChanged 
        % callback needs to be created
        function bool = checkCreateVcf(~, Elem, elem_prop, Hobj, hobj_prop)
            
            if ~strcmp(elem_prop, 'Value')
                bool = false;
                return
            end
            
            % Check property attributes
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
            
            bool = prop_write_accessible && gui_element_editable; 

            % Do not create a new callback if one already exists (typically 
            % it means that a callback was manually defined in AppDesigner) 
            bool = bool && (isprop(Elem, 'ValueChangedFcn') && ...
                isempty(Elem.ValueChangedFcn));
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
    end
end

