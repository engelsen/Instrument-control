classdef MyNewSettingEvent < event.EventData
   
    properties
        SettingList
    end
    
    methods
        function this = MyNewSettingEvent(SettingList)
            p = inputParser();
            addOptional(p, 'SettingList', struct(), @isstruct);
            parse(p, SettingList);
            
            this.SettingList = p.Results.SettingList;
        end
    end
end

