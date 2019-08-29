classdef MyCursor < handle
    
    properties (GetAccess = public, SetAccess = protected)
        Axes                % Axes in which the cursor is plotted
        Line                % Line object that represents the cursor
    end
    
    properties (Access = protected)
        Figure              % Figure that contains Axes
        
        % Variables for the temporary storage of information during
        % processing the interaction callbacks
        originalWbmFcn
        originalWbuFcn
        originalXLimMode
        originalYLimMode
    end
    
    properties (Dependent = true)
        
        % User-friendly ways to refer to the properties of Line
        orientation         % vertical/horizontal
        value               % cursor position
    end
    
    methods (Access = public)
        function this = MyCursor(Axes, position, varargin)
            p = inputParser();
            p.KeepUnmatched = true;
            addParameter(p, 'orientation', 'vertical', @ischar);
            parse(p, varargin{:});
            
            % All the unmatched parameters will be passed to the line
            % constructor
            line_nv = struct2namevalue(p.Unmatched);
            
            this.Axes = Axes;
            this.Figure = Axes.Parent;
            
            % Draw the cursor line
            if strcmpi(p.Results.orientation, 'vertical')
                this.Line = xline(Axes, position, line_nv{:});
            else
                this.Line = yline(Axes, position, line_nv{:});
            end
            
            % Configure the line
            this.Line.ButtonDownFcn = @this.cursorButtonDownFcn;
        end
        
        function delete(this)
            delete(this.Line);
        end
    end
    
    methods (Access = protected)
        
        % Callback invoked when the cursor is clicked by mouse
        function cursorButtonDownFcn(this, ~, ~)
            
            % Freeze axes limits
            this.originalXLimMode = this.Axes.XLimMode;
            this.originalYLimMode = this.Axes.YLimMode;
            
            this.Axes.XLimMode = 'manual';
            this.Axes.YLimMode = 'manual';
            
            % Replace figure callbacks
            this.originalWbmFcn = this.Figure.WindowButtonMotionFcn;
            this.originalWbuFcn = this.Figure.WindowButtonUpFcn;
            
            this.Figure.WindowButtonMotionFcn = @this.localWbmFcn;
            this.Figure.WindowButtonUpFcn = @this.localWbuFcn;
        end
        
        % Replacement callback that is active when the cursor is being 
        % dragged 
        function localWbmFcn(this, ~, ~)
            
            % Move the cursor line to the current position of the mouse
            % tip withing the plot area.
            switch this.Line.InterceptAxis
                case 'x'
                    new_x = this.Axes.CurrentPoint(1,1);
                    new_x = min(new_x, this.Axes.XLim(2));
                    new_x = max(new_x, this.Axes.XLim(1));
                    this.Line.Value = new_x;
                case 'y'
                    new_y = this.Axes.CurrentPoint(1,2);
                    new_y = min(new_y, this.Axes.YLim(2));
                    new_y = max(new_y, this.Axes.YLim(1));
                    this.Line.Value = new_y;
            end
        end
        
        % Replacement callback that is active when the cursor is being 
        % dragged
        function localWbuFcn(this, ~, ~)
            
            % Restore the original figure callbacks when the cursor drag is
            % finished
            this.Figure.WindowButtonMotionFcn = this.originalWbmFcn;
            this.Figure.WindowButtonUpFcn = this.originalWbuFcn;
            
            % Restore the axes limits mode
            this.Axes.XLimMode = this.originalXLimMode;
            this.Axes.YLimMode = this.originalYLimMode;
        end
    end
    
    methods
        function val = get.orientation(this)
            try
                switch this.Line.InterceptAxis
                    case 'x'
                        val = 'vertical';
                    case 'y'
                        val = 'horizontal';
                    otherwise
                        val = '';
                end
            catch
                val = '';
            end
        end
        
        function val = get.value(this)
            try
                val = this.Line.Value;
            catch
                val = NaN;
            end
        end
    end
end

