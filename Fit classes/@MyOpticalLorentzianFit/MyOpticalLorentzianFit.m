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
        
        function centerCursors(this)
            
            % Center the range cursors
            centerCursors@MyFit(this);
            
            % Center the ref cursors
            if ~isempty(this.Axes) && ~isempty(this.RefCursors) ...
                    && all(isvalid(this.RefCursors))
                xlim = this.Axes.XLim;
                
                x1 = xlim(1)+0.2*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.2*(xlim(2)-xlim(1));
                
                this.RefCursors(1).value = x1;
                this.RefCursors(2).value = x2;
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
            addUserParam(this, 'eta_oc', ...
                'title',        '\eta overcoupled', ...
                'editable',     'off');
            addUserParam(this, 'eta_uc', ...
                'title',        '\eta undercoupled', ...
                'editable',     'off');
        end
        
        function calcUserParams(this)
            raw_lw = this.param_vals(2);
            
            if ~isempty(this.RefCursors)
                
                % Get the reference spacing from the position of cursors
                xmin = min(this.RefCursors.value);
                xmax = max(this.RefCursors.value);
                ref_spacing = xmax - xmin;
            else
                
                % Otherwise the reference spacing is the entire data range
                ref_spacing = this.Data.x(1)-this.Data.x(end);
            end
            
            this.lw = raw_lw*this.line_spacing*this.line_no/ref_spacing;
            a = this.param_vals(1);
            d = this.param_vals(4);
            R_min = 1 + 2*a/pi/raw_lw/d;
            this.eta_oc = (1 + sqrt(R_min))/2;
            this.eta_uc = (1 - sqrt(R_min))/2;
        end
        
        function acceptFitCallback(this, ~, ~)
            if ~isempty(this.RefCursors)
                
%                 Get the reference spacing from the position of cursors
                xmin = min(this.RefCursors.value);
                xmax = max(this.RefCursors.value);
                ref_spacing = xmax - xmin;
            else
                
%             Otherwise the reference spacing is the entire data range
                ref_spacing = this.Data.x(1)-this.Data.x(end);
            end
            ScaledData = MyTrace;
            ScaledData.x = (this.Data.x -this.param_vals(3)) * ...
                            this.line_spacing*this.line_no/ref_spacing/1e3;
            ScaledData.y = this.Data.y;
            ScaledData.name_x = 'Detuning';
            ScaledData.name_y = this.Data.name_y;
            ScaledData.unit_x = 'GHz';
            ScaledData.unit_y = this.Data.unit_y;
            
            ScaledFit = MyTrace;
            ScaledFit.x = (this.Fit.x - this.param_vals(3)) * ...
                           this.line_spacing*this.line_no/ref_spacing/1e3;
            ScaledFit.y = this.Fit.y;
            ScaledFit.name_x = 'Detuning';
            ScaledFit.name_y = this.Fit.name_y;
            ScaledFit.unit_x = 'GHz';
            ScaledFit.unit_y = this.Fit.unit_y;
            triggerNewProcessedData(this, 'traces', {copy(this.Fit),ScaledFit, ScaledData}, ...
                'trace_tags', {'_fit','_fit_scaled','_scaled'});
        end
    end
end

