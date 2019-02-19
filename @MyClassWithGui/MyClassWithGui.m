classdef MyClassWithGui < handle
    
    properties (GetAccess=public, SetAccess=private)
        Gui
    end
    
    events 
        NewSetting
    end
    
    methods
        
        function triggerNewSetting(this, varargin)
            p=inputParser;
            addParameter(p, 'setting_name', @iscellstr);
            parse(p, varargin{:});
            
            EventData=MyNewSettingEvent();
            
            notify(this, 'NewSetting', EventData);
        end
        
    end
    
    methods 
        
        function set.Gui(this, Val)
            assert(isa(Val, 'matlab.apps.AppBase'), ...
                'Gui must be a Matlab app.');
            this.Gui=Val;
        end
        
    end
end

