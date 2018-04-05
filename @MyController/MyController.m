classdef MyController
    properties
        InstrList
    end
    
    properties (Dependent=true)
        open_instruments
    end
    
    methods
        
        addInstrument(this,instr_handle)
        
        collateHeaders(this)
    end    
end
f