% Class that adds a pair of vertical reference cursors to MyFit

classdef MyFitRefCursors < MyFit
    
    properties (GetAccess = public, SetAccess = protected)
        RefCursors  MyCursor
    end
    
    methods (Access = public)
        function this = MyFitRefCursors(varargin)
            this@MyFit(varargin{:});
            
            if ~isempty(this.Axes)
                
                % Add two vertical reference cursors to set the frequency
                % scale
                xlim = this.Axes.XLim;
                x1 = xlim(1)+0.2*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.2*(xlim(2)-xlim(1));
                
                this.RefCursors = ...
                    [MyCursor(this.Axes, ...
                    'orientation', 'vertical', ...
                    'position', x1, ...
                    'Label','Ref 1', 'Color', [0, 0, 0.6]), ...
                    MyCursor(this.Axes, 'orientation', 'vertical', ...
                    'position', x2, ...
                    'Label','Ref 2', 'Color', [0, 0, 0.6])];
            end
        end
        
        function delete(this)
            if ~isempty(this.RefCursors)
                delete(this.RefCursors);
            end
        end
    end
end

