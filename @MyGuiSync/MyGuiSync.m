% A mechanism to implement the synchronization of app-based guis

classdef MyGuiSync < handle
    
    properties (GetAccess = public, SetAccess = private)
        
        Listeners = struct()
        
        % Non-event links.
        %
        %   GuiElement          - graphics object
        %   gui_element_prop    - property of graphics object to be updated
        %   inputProcessingFcn  - function, applied after a value is
        %                           inputed to GUI element
        %   outputProcessingFcn - function, applied before a new value is 
        %                           displayed in GUI element
        %   getTargetFcn
        %   setTargetFcn
        %   Listener            - PostSet listener handle
        Links
        
        % If App defines updateGui function
        update_gui_defined = false
    end
    
    properties (Access = protected)
        
        % There properties are stored for cleanup purposes and not to be
        % used from the outside
        App = []
        KernelObj = []
    end
    
    methods (Access = public)     
        function this = MyGuiSync(App, KernelObj)
            p = inputParser();
            addRequired(p, 'App');
            addOptional(p, 'KernelObj', [], @(x)isa(x, 'handle'));
            parse(p, App, KernelObj);
            
            this.App = App;
            this.Listeners.AppDeleted = addlistener(App, ...
                'ObjectBeingDeleted', @(~, ~)delete(this));
            
            this.update_gui_defined = ismethod(this.App, 'updateGui');
            
            if ~ismember('KernelObj', p.UsingDefaults)
                
                % Kernel object triggers events that update gui 
                this.KernelObj=KernelObj;
                
                try
                    this.Listeners.NewSetting=addlistener(KernelObj, ...
                        'NewSetting', @this.newSettingCallback);
                catch
                end
                
                try
                    this.Listeners.NewData=addlistener(KernelObj, ...
                        'NewData', @(~, ~)updatePlot(App));
                catch
                end
                
                this.Listeners.KernelObjDeleted=addlistener(KernelObj, ...
                    'ObjectBeingDeleted', @this.kernelDeletedCallback);
            end
            
            % Set up a timer that can be used to periodically update the
            % gui
            this.UpdateTimer = timer('ExecutionMode', 'fixedDelay', ...
                'TimerFcn', @(~,~)updateGui(this.App));
        end
        
        function delete(this)
            
            % Delete listeners
            try
                lnames=fieldnames(this.Listeners);
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
            
            % Delete the update timer
            try
                delete(this.UpdateTimer);
            catch
                fprintf('Could not delete the update timer.\n')
            end
            
            % Delete the core object if present
            if ~isempty(this.KernelObj)
                try
                    % Check if the instrument object has appropriate method. This
                    % is a safety measure to never delete a file by accident if 
                    % it happens to be a valid file name.
                    if ismethod(this.KernelObj, 'delete')
                        delete(this.KernelObj);
                    else
                        fprintf(['App kernel object of class ''%s'' ' ...
                            'does not have ''delete'' method.\n'], ...
                            class(this.KernelObj))
                    end
                catch
                    fprintf('Could not delete the core object.\n')
                end
            end
        end
        
        
        % prop_tag is a reference to an element of app 
        function addLink(this, Elem, prop_ref, varargin)
            
            % Parse function inputs
            p = inputParser();
            p.KeepUnmatched = true;
            addParameter(p, 'create_callback', true, @islogical);
            addParameter(p, 'event_update', true, @islogical);
            parse(p, Elem, prop_tag, varargin{:});
            
            % Make the list of unmatched name-value pairs for subroutine 
            sub_varargin = struct2namevalue(p.Unmatched);
             
            % Make sure the reference starts with a dot and convert to
            % subreference structure
            if prop_ref(1)~='.'
                PropSubs = str2substruct(['.',prop_ref]);
            else
                PropSubs = str2substruct(prop_ref);
            end
            
            % Check if the specified target is accessible for reading
            try
                subsref(this.App, PropSubs);
            catch
                disp(['Property referenced by ' prop_ref ...
                    ' is not accessible, the corresponding GUI ' ...
                    'element will be not linked and disabled.'])
                Elem.Enable = 'off';
                return
            end
            
            % Create the basis of link structure (everything except for 
            % set/get functions)
            Link = makeLinkBasis(this, Elem, prop_ref, sub_varargin{:});
            
            % Find the handle object to which the end property belongs and
            % the end property name
            Hobj = this.App;
            hobj_name = 'App';
            
            RelSubs = PropSubs;     % Subreference relative to Hobj.(prop)
            hobj_prop = subsref(this.App, PropSubs(1));
            
            for i=1:length(PropSubs)-1
                testvar = subsref(this.App, PropSubs(1:end-i));
                if isa(testvar, 'handle')
                    Hobj = testvar;
                    hobj_name = PropSubs(end-i).subs;
 
                    RelSubs = PropSubs(end-i+2:end);
                    hobj_prop = subsref(this.App,PropSubs(1:end-i+1));
                    
                    break
                end
            end
            
            % Assign the function that returns the value of reference
            Link.getTargetFcn = createGetTargetFcn(this, Hobj, ...
                hobj_prop, RelSubs);
            
            % Check if ValueChanged callback needs to be created
            create_callback = p.Results.create_callback && ...
                checkCreateVcf(this, Elem, elem_prop, Hobj, hobj_prop);
            
            if create_callback
                
                % A public CreateCallback method needs to intorduced in the
                % app, as officially Matlab apps do not support external
                % callback assignment (as of the version of Matlab 2019a)
                assert(ismethod(this.App, 'publicCreateCallbackFcn'), ...
                    ['Matlab app must define a public wrapper for ' ...
                    'createCallbackFcn in order for GuiSync to be able to ' ...
                    'automatically assign ValueChanged callbacks. ' ...
                    'The wrapper method must have signature ' ...
                    'publicCreateCallbackFcn(app, callbackFunction).']);
                
                % Assign the function that sets new value to reference
                Link.setTargetFcn = createSetTargetFcn(this, Hobj, ...
                    hobj_prop, RelSubs);
                
                Elem.ValueChangedFcn = publicCreateCallbackFcn(this.App, ...
                    createValueChangedCallback(this, LinkStruct));
            end
            
            % Attempt creating a callback to PostSet event for the target 
            % property. If such callback is not created, the link needs to 
            % be updated manually.
            if p.Results.event_update
                try
                    Link.Listener = addlistener(Hobj, hobj_prop, ...
                        'PostSet', createPostSetCallback(this, LinkStruct));
                    
                    
                    l_name = [hobj_name, hobj_prop, 'PostSet']; 
                    
                    % Make sure the listener name is unique in the
                    % structure
                    l_name = matlab.lang.makeUniqueStrings(l_name, ...
                        fieldnames(this.Listeners));
                    
                    % Store listener handle also in the Listener structure
                    % for deletion
                    this.Listeners.(l_name) = Link.Listener;
                    
                    return
                catch 
                end
            end
            
            % Store the link structure
            this.Links = [this.Links, Link];
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
        
        % Find and update a particular GUI element
        % Arg2 can be a link structure of a GUI element for which the
        % corresponding link structure needs to be found.
        function updateLinkedElement(this, Arg2)
            if isstruct(Arg2)
                Link = Arg2;
                
                % Elements updated by callbacks should not be updated
                % manually
                if ~isempty(Link.Listener)
                    return
                end
                
                val = Link.getTargetFcn();
                if ~isempty(Link.outputProcessingFcn)
                    val = Link.outputProcessingFcn(val);
                end
                
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
                if this.update_gui_defined
                    updateGui(this.App);
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

                if ~isfield(Link, 'Listener')

                    % Update non event based links
                    updateLinkedElements(this);

                    % Optionally execute the update function defined within 
                    % the App
                    if this.update_gui_defined
                        updateGui(this.App);
                    end
                end
            end
            
            f = @valueChangedCallback;
        end
        
        function f = createGetTargetFcn(~, Obj, prop_name, S)
            function val = refProp()
                val = Obj.(prop_name);
            end
            
            function val = subsrefProp(val)
                val = subsref(Obj.(prop_name), S, val);
            end
            
            if isempty(S)
                
                % Faster way to access property
                f = @refProp;
            else
                
                % More general way to access property
                f = @subsrefProp;
            end
        end
        
        function f = createSetTargetFcn(~, Obj, prop_name, S)
            function assignProp(val)
                Obj.(prop_name) = val;
            end
            
            function subsasgnProp(val)
                Obj.(prop_name) = subsasgn(Obj.(prop_name), S, val);
            end
            
            if isempty(S)
                
                % Faster way to assign property
                f = @assignProp;
            else
                
                % More general way to assign property
                f = @subsasgnProp;
            end
        end
        
        % Check if a listener to an event already exists 
        function bool = hasListener(this, Obj, event_name)
            l_names = fieldbames(this.Listeners);
            
            bool = false;
            for i=1:length(l_names)
                L = this.Listeners.(l_names{i});
                if isequal(L.EventName, event_name) && isequal(L.Source{1}, Obj)
                    bool = true;
                end
            end
        end
        
        %% Subroutines of addLink
        
        % Parse input and create the base of Link structure
        function Link = makeLinkBase(~, Elem, prop_ref, varargin)
            
            % Parse function inputs
            p=inputParser();

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

            parse(p, Elem, prop_ref, varargin{:});
            
            assert(isempty( ...
                arrfun(@(x) isequal(p.Results.Elem, x.GuiElement), ...
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
                
                % Select between the default on and off colors. 
                Link.outputProcessingFcn = @(x)select(x, ...
                    MyAppColors.lampOn(), MyAppColors.lampOff());
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
    end
    
    %% Set and Get methods
    methods
        function set.App(this, Val)
            assert(isa(Val, 'matlab.apps.AppBase'), ...
                'App must be a Matlab app.');
            this.App=Val;
        end
    end
end

