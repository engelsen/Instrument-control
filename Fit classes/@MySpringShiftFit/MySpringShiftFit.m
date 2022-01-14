classdef MySpringShiftFit < MyFitParamScaling
    properties (GetAccess = public, SetAccess = protected)
        RefCursors  MyCursor
        SpikeCursors MyCursor

    end
    methods (Access = public)
        function this = MySpringShiftFit(varargin)
            this@MyFitParamScaling( ...
                'fit_name',         'Optomechanical spring shift', ...
                'fit_function',     'e*4*(x-c)*b/2/((x-c)^2+(b/2)^2)^2 + 1/pi*a*b/2/((x-c)^2+(b/2)^2)+d', ...
                'fit_tex',          '$$e\frac{4(x-c)b/2}{((x-c)^2+(b/2)^2)^2} + \frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d$$', ...
                'fit_params',       {'a','b','c','d','e'}, ...
                'fit_param_names',  {'Absorption amplitude','Width','Center','Offset', 'OM shift amplitude'}, ...
                varargin{:});
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

                x1_spike = xlim(1)+(xlim(2)-xlim(1))/3;
                x2_spike = xlim(2)-(xlim(2)-xlim(1))/3;
                
                this.SpikeCursors = ...
                    [MyCursor(this.Axes, ...
                    'orientation', 'vertical', ...
                    'position', x1_spike, ...
                    'Label','Spike removal 1', 'Color', [0, 0, 0.6]), ...
                    MyCursor(this.Axes, 'orientation', 'vertical', ...
                    'position', x2_spike, ...
                    'Label','Spike removal 2', 'Color', [0, 0, 0.6])];
            end
        end
        function delete(this)
            if ~isempty(this.RefCursors)
                delete(this.RefCursors);
            end
            if ~isempty(this.SpikeCursors)
                delete(this.SpikeCursors);
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
                
                x1_spike = xlim(1)+(xlim(2)-xlim(1))/3;
                x2_spike = xlim(2)-(xlim(2)-xlim(1))/3;
                
                this.SpikeCursors(1).value = x1_spike;
                this.SpikeCursors(2).value = x2_spike;
            end
        end
    end
    
    methods (Access = protected)
        function ind=findDataSelection(this)
            if this.enable_range_cursors
                xmin = min(this.RangeCursors.value);
                xmax = max(this.RangeCursors.value);
                ind = (this.Data.x>xmin & this.Data.x<=xmax);
            else
                ind = true(1, length(this.Data.x));
            end
            % Removing the spike on the resonance
            if ~isempty(this.SpikeCursors)
                x = this.Data.x(ind);
                y = this.Data.y(ind);                
    %           Get the reference spacing from the position of cursors
                ind_spike = (x > min(this.SpikeCursors.value)) & ...
                            (x < max(this.SpikeCursors.value));
                y_spike = y(ind_spike);
                Spike = max(abs(y_spike));
                IndSpike = find(abs(this.Data.y) == Spike);
                ind(IndSpike) = 0;
            end
            
        end
        
        function calcInitParams(this)
            ind = this.data_selection;
            
            x = this.Data.x(ind);
            y = this.Data.y(ind);

            this.lim_upper=[0,Inf,Inf,Inf,Inf];
            this.lim_lower=[-Inf,0,-Inf,-Inf,0];
           
            rng_x = max(x)-min(x);
            try
                [max_val, max_loc, max_width, max_prom] = findpeaks(y, x,...
                    'MinPeakDistance', rng_x/2, 'SortStr', 'descend',...
                    'NPeaks', 1);
            catch ME
                warning(ME.message)
            end

            % Finds peaks on the negative signal (max 1 peak)
            try
                [min_val, min_loc, min_width, min_prom] = findpeaks(-y, x,...
                    'MinPeakDistance', rng_x/2, 'SortStr', 'descend',...
                    'NPeaks', 1);
            catch ME
                warning(ME.message)
            end

            if min_prom==0 && max_prom==0
                warning(['No peaks were found in the data, giving ' ...
                    'default initial parameters to fit function'])
                return
            end
            % Width
            p_in(2) = abs(min_loc-max_loc)*sqrt(3);
            
            % OM Amplitude
            p_in(5) = abs(max_val + min_val)*p_in(2)^2/6/sqrt(3);
            
            % Center
            p_in(3) = (min_loc+max_loc)/2;
            
            % Offset
            p_in(4) = mean(y);
            
            % Absorption amplitude
%             p_in(1) = -abs(abs(max_val - p_in(4)) - abs(min_val - p_in(4)))*pi*p_in(2)/2;
            p_in(1) = -abs(max_val - min_val)*pi*p_in(2)/2/p_in(4);
            
            
            this.param_vals = p_in;
            this.lim_lower(2)=0.01*p_in(2);
            this.lim_upper(2)=100*p_in(2);
        end
        
        function genSliderVecs(this)
            genSliderVecs@MyFit(this);
            
            try 
                
                %We choose to have the slider go over the range of
                %the x-values of the plot for the center of the
                %Lorentzian.
                this.slider_vecs{3}=...
                    linspace(this.Fit.x(1),this.Fit.x(end),101);
                %Find the index closest to the init parameter
                [~,ind]=...
                    min(abs(this.param_vals(3)-this.slider_vecs{3}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{3})),'Value',ind-1);
            catch 
            end
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
            ind = this.data_selection;
            ScaledData = MyTrace;
            ScaledData.x = (this.Data.x(ind) -this.param_vals(3)) * ...
                            this.line_spacing*this.line_no/ref_spacing/1e3;
            ScaledData.y = this.Data.y(ind);
            ScaledData.name_x = 'Detuning';
            ScaledData.name_y = '$\delta\Omega_m$';
            ScaledData.unit_x = 'GHz';
            ScaledData.unit_y = 'Hz';
            
            ScaledFit = MyTrace;
            ScaledFit.x = (this.Fit.x - this.param_vals(3)) * ...
                           this.line_spacing*this.line_no/ref_spacing/1e3;
            ScaledFit.y = this.Fit.y;
            ScaledFit.name_x = 'Detuning';
            ScaledFit.name_y = '$\delta\Omega_m$';
            ScaledFit.unit_x = 'GHz';
            ScaledFit.unit_y = 'Hz';
            triggerNewProcessedData(this, 'traces', {copy(this.Fit),ScaledFit, ScaledData}, ...
                'trace_tags', {'_fit','_fit_scaled','_scaled'});
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
            addUserParam(this, 'eta_c', ...
                'title',        '\eta_c', ...
                'editable',     'on', ...
                'default',       0.5);
            addUserParam(this, 'eta_r', ...
                'title',        '\eta_r (P_{ref} / P_{in})', ...
                'editable',     'on', ...
                'default',       0.5); 
            addUserParam(this, 'P_in', ...
                'title',        'Input power (uW)', ...
                'editable',     'on', ...
                'default',       1);
            addUserParam(this, 'WL', ...
                'title',        'Wavelength (nm)', ...
                'editable',     'on', ...
                'default',       1550);
            addUserParam(this, 'f_m', ...
                'title',        'f_m (MHz)', ...
                'editable',     'on', ...
                'default',       1);
            addUserParam(this, 'lw_m', ...
                'title',        '\Gamma_m/2\pi (Hz)', ...
                'editable',     'on', ...
                'default',       1);
            addUserParam(this, 'T', ...
                'title',        'T (K)', ...
                'editable',     'on', ...
                'default',       300);
            addUserParam(this, 'g0', ...
                'title',        'g_0 (kHz)', ...
                'editable',     'off');
            addUserParam(this, 'lw', ...
                'title',        'Linewidth (GHz)', ...
                'editable',     'off');
            addUserParam(this, 'C0', ...
                'title',        'C_0', ...
                'editable',     'off');
            addUserParam(this, 'Cq', ...
                'title',        'C_q', ...
                'editable',     'off');
        end
        
        function calcUserParams(this)

            if ~isempty(this.RefCursors)
                
%               Get the reference spacing from the position of cursors
                
                xmin = min(this.RefCursors.value);
                xmax = max(this.RefCursors.value);
                ref_spacing = xmax - xmin;
            else
                
%             Otherwise the reference spacing is the entire data range
                ref_spacing = this.Data.x(1)-this.Data.x(end);
            end
            % scaling from seconds to MHz
            
            scale_factor = this.line_spacing*this.line_no/ref_spacing;
            raw_lw = this.param_vals(2);
            this.lw = raw_lw*scale_factor/1e3;
            
            f0 = this.eta_c * (sqrt(this.eta_r)*this.P_in*1e-6) /...
                (6.62607004e-34*physconst('LightSpeed') / (this.WL*1e-9))/...
                (2*pi);
            this.g0 = sqrt(this.param_vals(5) / f0) * scale_factor* 1e3;
            this.C0 = 4*(this.g0*1e3)^2 / (this.lw*1e9) / this.lw_m;
            
            this.Cq = (4 * this.eta_c * sqrt(this.eta_r)*(this.P_in*1e-6)*(this.f_m*1e6))/...
                      (this.lw*2*pi*1e9 * 1.38e-23 * this.T * physconst('LightSpeed') / (this.WL*1e-9));

        end
    end
    
    methods (Access = protected)
        function sc_vals = scaleFitParams(~, vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            sc_vals(1)=vals(1)/(std_y*std_x);
            sc_vals(2)=vals(2)/std_x;
            sc_vals(3)=(vals(3)-mean_x)/std_x;
            sc_vals(4)=(vals(4)-mean_y)/std_y;
            sc_vals(5)=vals(5) / std_y / std_x^2;
        end
        
        %Converts scaled coefficients to real coefficients
        function vals = unscaleFitParams(~, sc_vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            vals(1)=sc_vals(1)*std_y*std_x;
            vals(2)=sc_vals(2)*std_x;
            vals(3)=sc_vals(3)*std_x+mean_x;
            vals(4)=sc_vals(4)*std_y+mean_y;
            vals(5)=sc_vals(5) * std_y * std_x^2;
        end
    end
    
end