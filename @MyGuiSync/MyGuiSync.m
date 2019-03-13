% A mechanism to fascilitate synchronization of app-based guis

classdef MyGuiSync < handle
    
    properties (GetAccess = public, SetAccess = private)
        Listeners
        LinkedElements % Array of graphics objects
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
            addRequired(p, App);
            addOptional(p, KernelObj, [], @ishandle);
            parse(p, App, KernelObj);
            
            this.App = App;
            this.Listeners.AppDeleted = addlistener(App, ...
                'ObjectBeingDeleted', @(~, ~)delete(this));
            
            if ~ismember('KernelObj', p.UsingDefaults)
                
                % Kernel object triggers events that update gui 
                this.KernelObj=KernelObj;
                
                try
                    this.Listeners.NewSetting=addlistener(KernelObj, ...
                        'NewSetting', @(Src, EventData)newSettingCallback(this, ...
                        Src, EventData));
                catch
                end
                
                try
                    this.Listeners.NewSetting=addlistener(KernelObj, ...
                        'NewData', @(~, ~)updatePlot(App));
                catch
                end
                
                this.Listeners.KernelObjDeleted=addlistener(KernelObj, ...
                    'ObjectBeingDeleted', @(~, ~)coreObjDeletedCallback(this));
            end
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
            
            % Delete the core object if present
            if ~isempty(this.KernelObj)
                try
                    % Check if the instrument object has appropriate method. This
                    % is a safety measure to never delete a file by accident if 
                    % it happens to be a valid file name.
                    if ismethod(this.KernelObj, 'delete')
                        delete(this.KernelObj);
                    else
                        fprintf(['App core object of class ''%s'' does ' ...
                            'not have ''delete'' method.\n'], ...
                            class(this.KernelObj))
                    end
                catch
                    fprintf('Could not delete the core object.\n')
                end
            end
        end
        
        function addLink()
        end
    end
       
    methods (Access = protected)  
        function coreObjDeletedCallback(this)
            % Switch off the AppBeingDeleted callback in order to prevent
            % an infinite loop
            this.Listeners.AppDeleted.Enabled=false;
            
            delete(this.App);
            delete(this);
        end
        
        % Update 
        function newSettingCallback(this, Src, EventData)
            
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

