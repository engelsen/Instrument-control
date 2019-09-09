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
end

