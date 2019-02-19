% Class that implements a mechanism to fascilitate synchronization of
% app-based guis

classdef MyAppSync < handle
    
    properties (GetAccess=public, SetAccess=private)
        Listeners
        LinkedElements % Array of graphics objects
    end
    
    properties (Access=private)
        % There properties are stored for cleanup purposes and not to be
        % used from the outside
        App = [];
        CoreObj = []
    end
    
    methods
        
        function this=MyAppSync(App, CoreObj)
            this.App=App;
            this.Listeners.AppDeleted=addlistener(App, ...
                'ObjectBeingDeleted', @(~, ~)delete(this));
            
            if nargin()==2
                
                this.CoreObj=CoreObj;
                
                try
                    this.Listeners.NewSetting=addlistener(CoreObj, ...
                        'NewSetting', @(Src, EventData)newSettingCallback(this, ...
                        Src, EventData));
                catch
                end
                
                try
                    this.Listeners.NewSetting=addlistener(CoreObj, ...
                        'NewData', @(~, ~)updatePlot(App));
                catch
                end
                
                this.Listeners.CoreObjDeleted=addlistener(CoreObj, ...
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
            if ~isempty(this.CoreObj)
                try
                    % Check if the instrument object has appropriate method. This
                    % is a safety measure to never delete a file by accident if 
                    % app.Instr happens to be a valid file name.
                    if ismethod(this.CoreObj, 'delete')
                        delete(this.CoreObj);
                    else
                        fprintf(['App core object of class ''%s'' does ' ...
                            'not have ''delete'' method.\n'], ...
                            class(this.CoreObj))
                    end
                catch
                    fprintf('Could not delete the core object.\n')
                end
            end
        end
        
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

