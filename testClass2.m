classdef testClass2 < MyInstrument
    
    properties
        Property1
    end
    
    methods
        
        function setcmd1(this, obj, val)
            obj.cmd1 = val;
        end
    end
end

