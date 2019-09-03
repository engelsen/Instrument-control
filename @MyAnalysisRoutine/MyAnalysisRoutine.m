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
end

