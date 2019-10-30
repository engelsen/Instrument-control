% Class that contains functionality of transferring trace to Collector and
% then to Daq

classdef MyDataSource < handle
    
    properties (Access = public)
        
        % An object derived from MyTrace
        Trace
    end
    
    events
        NewData 
    end
    
    methods (Access = public)
        
        function this = MyDataSource()
            this.Trace = MyTrace();
        end
        
        % Trigger event signaling the acquisition of a new trace. 
        % Any properties of MyNewDataEvent can be set by indicating the
        % corresponding name-value pars in varargin. For the list of  
        % options see the definition of MyNewDataEvent.  
        function triggerNewData(this, varargin)
            EventData = MyNewDataEvent(varargin{:});
            
            % Pass trace by value to make sure that it is not modified 
            % before being transferred
            if isempty(EventData.Trace)
                
                % EventData.Trace can be set either automaticallt here or
                % explicitly as a name-value pair supplied to the function. 
                EventData.Trace = copy(this.Trace);
            end
            
            notify(this, 'NewData', EventData);
        end
        
    end
    
    methods
        function set.Trace(this, Val)
            assert(isa(Val, 'MyTrace'), ['Trace must be a derivative ' ...
                'of MyTrace class.'])
            this.Trace = Val;
        end
    end
end

