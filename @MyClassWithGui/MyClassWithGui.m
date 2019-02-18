classdef MyClassWithGui < handle
    
    properties (GetAccess=public, SetAccess=private)
        App
    end
    
    properties (Access=private)
        GuiDestListener
    end
    
    events 
        NewSetting
    end
    
    methods
        
        function assignGui(this, App)
            this.App=App;
            % Set listeners so that the destruction of Gui destroys the
            % object and the destruction of object closes the Gui
            this.GuiDestListener=...
                addlistener(this.App,'ObjectBeingDestroyed',@(~,~)delete(this.App));
        end
        
        function triggerNewSetting(this, varargin)
            p=inputParser;
            addParameter(p, 'setting_name', @iscellstr);
            parse(p, varargin{:});
            
            EventData=MyNewSettingEvent();
            
            notify(this, 'NewSetting', EventData);
        end
        
        function guiDeletedCallback(this)
            delete(this.Listeners)
            delete(this)
        end
        
    end
    
end

