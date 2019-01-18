% Class that contains functionality of transferring trace to Collector and
% then to Daq

classdef MyDataSource < handle
    
    properties (GetAccess=public, SetAccess={?MyClassParser})     
        % name is sometimes used as identifier in listeners callbacks, so
        % it better not to be changed after the object is created. 
        % Granting MyClassParser access to this variable allows to 
        % conveniently assign it in a subclass constructor from name-value 
        % pairs. 
        name='MyDataSource'
    end
    
    % There does not seem to be a way to have a read-only protected access
    % for a handle variable, so keep it public
    properties (Access=public)
        Trace
    end
    
    events
        NewData 
    end
    
    methods (Access=public)
        
        function this=MyDataSource()
            this.Trace=MyTrace(); % Create an empty trace object
        end
        
        %Trigger event signaling the acquisition of a new trace. 
        %Any properties of MyNewDataEvent can be set by indicating the
        %corresponding name-value pars in varargin. For the list of options 
        %see the definition of MyNewDataEvent.  
        function triggerNewData(this, varargin)
            EventData = MyNewDataEvent(varargin{:});
            EventData.src_name=this.name;
            % Pass trace by value to make sure that it is not modified 
            % before being transferred
            EventData.Trace=copy(this.Trace);
            notify(this,'NewData',EventData);
        end
        
    end
    
    %% Set and get methods
    
    methods
        
        % Ensures that the instrument name is a valid Matlab variable
        function set.name(this, str)
            assert(ischar(str), ['The value assigned to ''name'' ' ...
                'property must be char'])
            if ~isempty(str)
                str=matlab.lang.makeValidName(str);
            else
                str=class(this);
            end
            this.name=str;
        end
        
        function set.Trace(this, Val)
            assert(isa(Val, 'MyTrace'), ['The value of Trace must be ' ...
                'of MyTrace class or its subcleass'])
            this.Trace=Val;
        end
    end
end

