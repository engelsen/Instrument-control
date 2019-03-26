% A mechanism to fascilitate synchronization of app-based guis

classdef MyGuiSync < handle
    
    properties (GetAccess = public, SetAccess = private)
        
        Listeners
        Links % Array of graphics objects
        %   GuiElement
        %   GuiElementProp
        %   hObj
        %   hObjProp
        %   hObjSubstruct
        %   input_prescaler
        %   inputProcessingFcn
        %   outputProcessingFcn
        %   update_event     'NewSetting', 'PostSet' or 'no'
        
        UpdateTimer
    end
    
    properties (Access = protected)
        
        % There properties are stored for cleanup purposes and not to be
        % used from the outside
        App = [];
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
        
        % Operation of addLink
        %
        %   option: callback_update true/false
        %
        % obj = top handle object
        % 
        % If isevent(obj, 'NewSetting') && callback_update
        %   ... define a callback using the framework of NewSetting
        % elseif issetobservable(obj, prop) && callback_update
        %   ... define a callback for PostSet
        % else
        %   ... add to the list which is updated manually, e.g. it is
        %   updated each time one of such values is reset
        %   (execute updateGui(app) if defined or updateLinks(app.Sync) otherwise)
        
        
        % prop_tag is a reference to an element of app 
        function addLink(this, Elem, prop_ref, varargin)
            
            % Make sure the reference starts with a dot and convert to
            % subreference structure
            if prop_ref(1)~='.'
                PropSubs = str2substruct(['.',prop_ref]);
            else
                PropSubs = str2substruct(prop_ref);
            end
            
            % Check if the specified reference is accessible
            try
                subsref(this.App, PropSubs);
            catch
                disp(['Property referenced by the tag ' prop_ref ...
                    ' is not accessible, the corresponding GUI ' ...
                    'element will be not linked and disabled.'])
                Elem.Enable = 'off';
                return
            end
            
            % Find the handle object to which the end property belongs as
            % well as the end property name
            Hobj = this.App;
            hobj_name = 'App';
            
            RelSubs = PropSubs;     % Subreference relative to Hobj
            prop_name = subsref(this.App, PropSubs(1));
            
            for i=1:length(PropSubs)-1
                testvar = subsref(this.App, PropSubs(1:end-i));
                if isa(testvar, 'handle')
                    Hobj = testvar;
                    hobj_name = PropSubs(end-i).subs;
 
                    RelSubs = PropSubs(end-i+1:end);
                    prop_name = subsref(this.App,PropSubs(1:end-i+1));
                    
                    break
                end
            end
            
            % Determine the type of link to be created
            if ismember('NewSetting', events(Hobj)) && is_event_update
                
                % Add a listener for the NewSetting event if it is not
                % already present               
                if ~hasListener(this, Hobj, 'NewSetting')
                    l_name = [hobj_name, 'NewSetting']; 
                    
                    % Make sure the listener name is unique in the
                    % structure
                    l_name = matlab.lang.makeUniqueStrings(l_name, fieldnames(this.Listeners));
                    
                    this.Listeners.(l_name) = addlistener(Hobj, 'NewSetting', @updatenewsetting);
                end
                
                % Add link and return
                addLinkNs(this, Elem, Hobj, RelSubs, varargin);
                
                return
            end
            
            if eventupdate
                try
                    addLinkPs(this, Elem, Hobj, RelSubs, varargin);
                    
                    l_name = [hobj_name, prop_name, 'PostSet']; 
                    
                    % Make sure the listener name is unique in the
                    % structure
                    l_name = matlab.lang.makeUniqueStrings(l_name, fieldnames(this.Listeners));
                    
                    this.Listeners.(l_name) = addlistener(Hobj, prop_name, 'PostSet', @updatepostset);
                    
                    return
                catch
                end
            end
            
            % Create a non-event link
            addLinkMu(this, Elem, PropSubs, varargin);
        end
        
        % No update event
        function addLinkMu(this, elem, prop_tag, varargin)
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
            if strcmpi(elem.Type, 'uilamp') && ~iscolor(target_val)
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
        end
        
        
        function updateGui(this)
            arrayfun(@(x) updateGuiElement(this, x), this.LinkedElements);
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
        
        % Update 
        function newSettingCallback(this, Src, EventData)
            
        end
        
        function postSetCallback(this, Hobj, S)
            Elem.Value = ;
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

