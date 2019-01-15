%Class for NewData events that are generated by MyInstrument
classdef MyNewDataEvent < event.EventData
    properties
        % Handle of the instrument that triggered the event. Usefult for
        % passing the event data forward, e.g. by triggering 
        % NewDataWithHeaders 
        Instr
        
        % If true then MyCollector does not acquire new measurement headers 
        % for this trace. Setting no_new_header = false allows transferring 
        % an existing trace to Daq by triggering NewData.
        no_new_header = false
        
        % If the new data should be automatically saved by Daq.
        save = false
        
        % If 'save' is true and 'filename' is not empty, Daq uses the 
        % supplied file name to save the trace. This file name is relative 
        % to the measurement session folder.
        filename = '' 
    end
    
    methods 
        
        % Use parser to process properties supplied as name-value pairs via
        % varargin
        function this=MyNewDataEvent(varargin)
            P=MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
    end
end