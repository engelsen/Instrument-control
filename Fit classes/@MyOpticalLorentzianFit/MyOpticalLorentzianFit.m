% Lorenzian fit with additional capabilities for the calibration of optical
% linewidth

classdef MyOpticalLorentzianFit < MyLorentzianFit
    properties (GetAccess = public, SetAccess = protected)
        RefCursors  MyCursor
    end
    
    methods (Access = public)
        function this = MyOpticalLorentzianFit(varargin)
            this@MyLorentzianFit(varargin{:});
            
            if ~isempty(this.Axes)
                
                % Add two vertical reference cursors to set the frequency
                % scale
                xlim = this.Axes.XLim;
                x1 = xlim(1)+0.2*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.2*(xlim(2)-xlim(1));
                
                this.RefCursors = ...
                    [MyCursor(this.Axes, x1, 'orientation', 'vertical', ...
                    'Label','Ref 1', 'Color', [0, 0, 0.6]), ...
                    MyCursor(this.Axes, x2, 'orientation', 'vertical', ...
                    'Label','Ref 2', 'Color', [0, 0, 0.6])];
            end
        end
    end
    
    methods (Access = protected)
        function createUserParamList(this)
            addUserParam(this, 'line_spacing', ...
                'title',        'Reference line spacing (MHz)', ...
                'editable',     'on', ...
                'default',      1);
            addUserParam(this, 'line_no', ...
                'title',        'Number of reference lines', ...
                'editable',     'on', ...
                'default',      1);
            addUserParam(this, 'lw', ...
                'title',        'Linewidth (MHz)', ...
                'editable',     'off');
        end
        
        function calcUserParams(this)
            raw_lw = this.param_vals(2);
            
            if ~isempty(this.RefCursors)
                
                % Get the reference spacing from the position of cursors
                xmin = min(this.RangeCursors.value);
                xmax = max(this.RangeCursors.value);
                ref_spacing = xmax - xmin;
            else
                
                % Otherwise the reference spacing is the entire data range
                ref_spacing = this.Data.x(1)-this.Data.x(end);
            end
            
            this.lw = raw_lw*this.line_spacing*this.line_no/ref_spacing;
        end
    end
end

