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
        originalWbdFcn
        originalXLimMode
        originalYLimMode
        
        was_dragged = false
        
        % Minimum interval between the subsequent updatings of the cursor 
        % position when it is dragged (s)
        DragDelay
        
        % Time of the previous drag
        TlastDrag
    end
    
    properties (Dependent = true)
        
        % User-friendly ways to refer to the properties of Line
        orientation         % vertical/horizontal
        value               % cursor position
    end
    
    methods (Access = public)
        function this = MyCursor(Axes, varargin)
            p = inputParser();
            p.KeepUnmatched = true;
            addRequired(p, 'Axes', @isaxes);
            addParameter(p, 'position', []);
            addParameter(p, 'orientation', 'vertical', @ischar);
            parse(p, Axes, varargin{:});
            
            % All the unmatched parameters are assumed to be line 
            % parameters and will be passed to the line constructor
            line_nv = struct2namevalue(p.Unmatched);
            
            this.Axes = Axes;
            this.Figure = Axes.Parent;
            
            this.DragDelay = milliseconds(100);
            
            % Draw the cursor line
            if strcmpi(p.Results.orientation, 'vertical')
                if ~isempty(p.Results.position)
                    pos = p.Results.position;
                else
                    pos = (this.Axes.XLim(1)+this.Axes.XLim(2))/2;
                end
                
                this.Line = xline(Axes, pos, line_nv{:});
            else
                if ~isempty(p.Results.position)
                    pos = p.Results.position;
                else
                    pos = (this.Axes.YLim(1)+this.Axes.YLim(2))/2;
                end
                
                this.Line = yline(Axes, pos, line_nv{:});
            end
            
            % Configure the line
            this.Line.ButtonDownFcn = @this.cursorButtonDownFcn;
            
            % Do not display cursors in legends
            this.Line.Annotation.LegendInformation.IconDisplayStyle='off';
        end
        
        function delete(this)
            delete(this.Line);
        end
    end
    
    methods (Access = protected)
        
        % Callback invoked when the cursor is clicked by mouse
        function cursorButtonDownFcn(this, ~, ~)
            
            % Freeze the limits of axes
            this.originalXLimMode = this.Axes.XLimMode;
            this.originalYLimMode = this.Axes.YLimMode;
            
            this.Axes.XLimMode = 'manual';
            this.Axes.YLimMode = 'manual';
            
            % Replace figure callbacks
            this.originalWbmFcn = this.Figure.WindowButtonMotionFcn;
            this.originalWbuFcn = this.Figure.WindowButtonUpFcn;
            this.originalWbdFcn = this.Figure.WindowButtonDownFcn;
            
            this.Figure.WindowButtonMotionFcn = @this.localWbmFcn;
            this.Figure.WindowButtonUpFcn = @this.localWbuFcn;
            this.Figure.WindowButtonDownFcn = @this.localWbdFcn;
            
            this.Line.Selected = 'on';
            
            this.TlastDrag = datetime('now');
        end
        
        % Replacement callback that is active when the cursor is being 
        % dragged 
        function localWbmFcn(this, ~, ~)
            this.was_dragged = true;
            
            Tnow = datetime('now');
            
            if (Tnow-this.TlastDrag) > this.DragDelay
                moveLineToMouseTip(this);
                this.TlastDrag = Tnow;
            end
        end
        
        % Replacement callback that is active when the cursor is being 
        % dragged
        function localWbuFcn(this, ~, ~)
            if this.was_dragged
                
                % If the cursor was dragged while the mouse button was 
                % down, finish the interaction 
                this.was_dragged = false;
                restoreAxes(this);
            else
                
                % If it was not dragged, disable the mouse motion callback 
                % and wait for a new mouse click to move the cursor
                this.Figure.WindowButtonMotionFcn = this.originalWbmFcn;
            end
        end
        
        % Replacement callback that is active when the cursor is being 
        % dragged 
        function localWbdFcn(this, ~, ~)
            moveLineToMouseTip(this);
            restoreAxes(this);
        end
        
        function moveLineToMouseTip(this)
            
            % Move the cursor line to the current position of the mouse
            % tip withing the plot area.
            switch this.Line.InterceptAxis
                case 'x'
                    new_x = this.Axes.CurrentPoint(1,1);
                    new_x = min(new_x, this.Axes.XLim(2));
                    new_x = max(new_x, this.Axes.XLim(1));
                    
                    if new_x ~= this.Line.Value
                        this.Line.Value = new_x;
                    end
                case 'y'
                    new_y = this.Axes.CurrentPoint(1,2);
                    new_y = min(new_y, this.Axes.YLim(2));
                    new_y = max(new_y, this.Axes.YLim(1));
                    
                    if new_y ~= this.Line.Value
                        this.Line.Value = new_y;
                    end
            end
        end
        
        % Restore the axes in the state before user interaction
        function restoreAxes(this)
            
            % Restore the original figure callbacks when the cursor drag is
            % finished
            this.Figure.WindowButtonMotionFcn = this.originalWbmFcn;
            this.Figure.WindowButtonUpFcn = this.originalWbuFcn;
            this.Figure.WindowButtonDownFcn = this.originalWbdFcn;

            % Restore the axes limits mode
            this.Axes.XLimMode = this.originalXLimMode;
            this.Axes.YLimMode = this.originalYLimMode;

            this.Line.Selected = 'off';
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
        
        function set.value(this, val)
            this.Line.Value = val;
        end
    end
end

