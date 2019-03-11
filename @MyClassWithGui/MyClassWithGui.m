classdef MyClassWithGui < handle
    
    properties (GetAccess=public, SetAccess=private)
        Gui
    end
    
    methods 
        
        function set.Gui(this, Val)
            assert(isa(Val, 'matlab.apps.AppBase'), ...
                'Gui must be a Matlab app.');
            this.Gui=Val;
        end
        
    end
end

