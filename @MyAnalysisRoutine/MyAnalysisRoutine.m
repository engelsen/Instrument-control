% Superclass for DAQ-compatible analysis routines
% Must accept Axes as an optional argument

classdef MyAnalysisRoutine < handle
    
    properties (Abstract, Access = public)
        Data    MyTrace
    end
    
    properties (Abstract, GetAccess = public, SetAccess = protected)
        Axes
    end
    
    events
        NewAnalysisTrace
    end
    
    methods (Access = public)
                
        %Triggered for transferring of the fit trace to DAQ
        function triggerNewAnalysisTrace(this, varargin)
            EventData = MyNewAnalysisTraceEvent(varargin{:});
            notify(this, 'NewAnalysisTrace', EventData);
        end
    end
    
    methods (Static, Access = public)
        
        % Method for validation of the compliance with this class, it is
        % useful when subclassig cannot be implemented, as in the case of
        % MATLAB apps (as of MATLAB 2019a).
        % Obj is either an object instance or the name of its class.
        function validate(Obj)
            if ischar(Obj)
                class_name = Obj;
            else
                class_name = class(Obj);
            end
            
            assert(ismember('Data', properties(class_name)), ...
                'Analysis routine must define ''Data'' property')
            assert(ismember('NewAnalysisTrace', events(class_name)), ...
                'Analysis routine must define ''NewAnalysisTrace'' event')
            assert(nargin(class_name) == -1, ...
                'Analysis routine accept varargin input')
        end
    end
end

