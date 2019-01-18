%Class for NewData events that are generated by MyDataSource and its
%subclasses, including MyInstrument

classdef MyNewDataEvent < event.EventData
    properties
        % Name of the instrument that triggered the event. Usefult for
        % passing the event data forward, e.g. by triggering 
        % NewDataWithHeaders 
        src_name = 'UnknownInstrument'
        
        % New acquired trace. Should be passed by value in order to prevent
        % race condition when multiple NewData events are triggered by 
        % the same instrument in a short period of time. Passing by value 
        % makes sure that the trace is not modified before it is received
        % by Daq.
        Trace
        
        % If false then MyCollector does not acquire new measurement  
        % headers for this trace. Setting new_header = false allows  
        % transferring an existing trace to Daq by triggering NewData.
        new_header = true
        
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
    
    %% Set and get methods
    
    methods
        % Ensures that the source name is a valid Matlab variable
        function set.src_name(this, str)
            assert(ischar(str), ['The value assigned to ''src_name'' ' ...
                'must be char'])
            if ~isempty(str)
                str=matlab.lang.makeValidName(str);
            else
                str='UnknownInstrument';
            end
            this.name=str;
        end
    end
end