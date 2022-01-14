% Routine for the calibration of mechanical displacement in a homodyne
% interferometer, where the oscillations are comparable to the scale of
% interference fringes, resulting in multiple sidebands observable in the
% displacement spectrum.

classdef MyDrivenMechDispCal < MyAnalysisRoutine
    
    properties (Access = public, SetObservable = true)
        Data    MyTrace
        
        % Minimum thereshold for peak search. If MinHeightCursor exists, it
        % has priority over the programmatically set value.
        min_peak_height     double
        
        lambda = 0 % optical wavelength (nm)
        
        mod_freq = 0    % modulation frequency (Hz)
    end
    
    properties (Access = public, Dependent = true, SetObservable = true)
        enable_cursor 
    end
    
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        Axes
        Gui
        
        MinHeightCursor    MyCursor
        
        beta = 0        % Phase modulation depth
        
        x0 = 0          % Mechanical oscillations amplitude
        
        theta = 0       % Quadrature angle
        
        disp_cal = 0    % Displacement calibration factor
        
        disp_cal_err = 0 %95% confidence interval for calibration factor
        
        sb_n = []       % Integrated sideband indices
        
        sb_pow = []     % Sideband powers
        
    end
    
    properties (Access = protected)
        
        % Line that displays the positions of peaks found
        PlottedPeaks 
    end
    
    methods (Access = public)
        function this = MyDrivenMechDispCal(varargin)
            p = inputParser();
            addParameter(p, 'Data', MyTrace());
            addParameter(p, 'Axes', [], @isaxes);
            addParameter(p, 'enable_cursor', true, @islogical);
            addParameter(p, 'enable_gui', true, @islogical);
            parse(p, varargin{:});
            
            this.Data = p.Results.Data;
            this.Axes = p.Results.Axes;
            
            if ~isempty(this.Axes) && isvalid(this.Axes)
                ylim = this.Axes.YLim;
                
                if isempty(this.Data)
                    pos = min(ylim(1)+0.30*(ylim(2)-ylim(1)), 10*ylim(1));
                else
                    pos = min(this.Data.y)*exp(0.5*(log(max(this.Data.y))-log(min(this.Data.y))));
                end
                
                this.MinHeightCursor = MyCursor(this.Axes, ...
                    'orientation',  'horizontal', ...
                    'position',     pos, ...
                    'Label',        'Peak threshold', ...
                    'Color',        [0.6, 0, 0]);
                
                this.min_peak_height = pos;
                
                this.enable_cursor = p.Results.enable_cursor;
            else
                this.min_peak_height = 1e-12;
            end
            
            % Gui is created right before the construction of object 
            % is over 
            if p.Results.enable_gui
                this.Gui = GuiDrivenMechDispCal(this);
            end
        end
        
        function delete(this)
            if ~isempty(this.PlottedPeaks)
                delete(this.PlottedPeaks)
            end
            if ~isempty(this.MinHeightCursor)
                delete(this.MinHeightCursor)
            end
        end
        
        % Calculate the depth of phase modulation from the hights of peaks
        % in the spectrum
        function calcBeta(this)
            min_y = this.min_peak_height;
            
            % Find peaks above the given threshold
            % Returned values: [y, x, widths, prominences]
            [peak_y, peak_x, peak_w, ~] = findpeaks( ...
                this.Data.y, this.Data.x, 'MinPeakHeight', min_y);
            
            n_peaks = length(peak_y);
            
            assert(n_peaks >= 3, ['Less than 3 peaks are found in '...
                'the data with given threshold (' num2str(min_y) '). ' ...
                'Phase modulation depth cannot be calculated.'])
                      
            % Check if the peaks are roughly equally spaced harmonics, if
            % not, use the pre-specified value of modulation frequency to
            % select the right peaks.
            peak_x_diff = peak_x(2:n_peaks)-peak_x(1:n_peaks-1);
            mod_f = mean(peak_x_diff);
            
            % Specify the tolerance to the mismatch of frequencies between 
            % the found modulation peaks
            mod_peak_tol = 0.1;
            
            if max(abs(peak_x_diff-mod_f))/mod_f > mod_peak_tol
                
                % Try using the approximate value of modulation frequency
                % that can be specified by the user.
                disp(['Distances between the found peaks are not ' ...
                    'regular, will use the pre-defined value of ' ...
                    'modulation frequency to post select peaks.']);
                
                if isempty(this.mod_freq) || this.mod_freq<=0
                    
                    % Prompt user to specify approximate modulation
                    % frequency. Show warning dialog if running in a gui
                    % mode or output warning in the command line otherwise.                        
                    if ~isempty(this.Gui)
                        Wd = warndlg(['Cannot identify modulation ' ...
                            'sidebands automatically. Please input ' ...
                            'an approximate value of modulation ' ...
                            'frequency and try again.'], 'Warning');
                        centerFigure(Wd);
                    else
                        warning(['An approximate value on modulation ' ...
                            'frequency must be specified by setting ' ...
                            'mod_freq property. Please specify the ' ...
                            'frequency and try again.']);
                    end
                    
                    return
                end
                
                mod_f = this.mod_freq;
            end
            
            %Improve the estimate of mechanical frequency
            
            max_search_band = [0.9*mod_f, 1.1*mod_f];
            
            [~, mech_peak_x] = max(this.Data.y((this.Data.x > min(max_search_band)) & ...
                (this.Data.x < max(max_search_band)))); 
            
            freq_search = this.Data.x(((this.Data.x > min(max_search_band)) & ...
                (this.Data.x < max(max_search_band))));
            
            mod_f = freq_search(mech_peak_x);
            
            % Delete the peaks that do not appear at the expected
            % frequencies of harmonics of the modulation frequency
            scaled_peak_x = peak_x/mod_f;
            sb_ind = [];
            for i = 1:n_peaks

                % Iterate over the sideband index i and find pairs of
                % sidebands
                [err, ind] = min(abs(scaled_peak_x - i));

                if (err/i < mod_peak_tol) && (err/i < mod_peak_tol) 

                    % Add the found indices to the list of sideband 
                    % peak indices
                    sb_ind = [sb_ind, ind]; 
                else
                    break
                end
            end

            % Select sideband peaks at the harmonics of the mechanical
            % frequency
            peak_y = peak_y(sb_ind); 
            peak_x = peak_x(sb_ind);
            peak_w = peak_w(sb_ind);
            
            % Take the integration width to be a few times the width of the
            % largest peak.
            int_w = 15*max(peak_w);
            
            n_peaks = length(peak_y);
            assert(n_peaks >= 3, ['Less than 3 peaks are found. ' ...
                'Phase modulation depth cannot be calculated.'])
            
            % Re-calculate the modulation frequency
            mod_f = (peak_x(end)-peak_x(1))/(n_peaks-1);
            
            %Re-construct the sideband indices
            
            sb_ind = round(peak_x/mod_f);
            
            % Display the found peaks
            if ~isempty(this.Axes) && isvalid(this.Axes)
                if ~isempty(this.PlottedPeaks)&&isvalid(this.PlottedPeaks)
                    set(this.PlottedPeaks,'XData',peak_x,'YData',peak_y);
                else
                    this.PlottedPeaks = line(this.Axes, ...
                        'XData', peak_x, 'YData', peak_y, 'Color', 'r', ...
                        'LineStyle', 'none', 'Marker', 'o');
                end
            end
            
            % Calculate areas under the peaks
            peak_int = zeros(1, n_peaks);
            for i = 1:n_peaks
                peak_int(i) = integrate(this.Data, peak_x(i)-int_w/2, ...
                    peak_x(i)+int_w/2);
            end
            
            % Scale by the maximum area for better fit convergence
            peak_norm = peak_int/max(peak_int);            
            
            % Find beta value by fitting
            
            Ft = fittype(@(beta,a,b,n) bessel_full(beta,a,b,n), 'independent', 'n', ...
                'coefficients', {'beta', 'a', 'b'});      

            Opts = fitoptions('Method', 'NonLinearLeastSquares',...
                'StartPoint',   [1, 1, 1],...
                'MaxFunEvals',  2000,...
                'MaxIter',      2000,...
                'TolFun',       1e-10,...
                'TolX',         1e-10);
            
            FitResult = fit(sb_ind(:), peak_norm(:), Ft, Opts);
            
            %Get 95% confidence interval on beta
            
            if n_peaks >= 4          
                FitConfint = confint(FitResult,.95);
                dbeta = FitConfint(2,1) - FitConfint(1,1);
            else
                dbeta = 0;
                warning('Confidence interval has not been calculated; too few sidebands included in the fit');
            end
            
            % Store the result in class variables
            this.beta = abs(FitResult.beta);
            this.mod_freq = mod_f;
            this.theta = 180*atan(sqrt(FitResult.b/FitResult.a))/pi;
            this.sb_n = sb_ind;
            this.sb_pow = peak_norm;
            
            if isempty(this.lambda) || this.lambda<=0
                    
                    % Prompt user to specify approximate wavelength. 
                    % Show warning dialog if running in a gui
                    % mode or output warning in the command line otherwise.                        
                    if ~isempty(this.Gui)
                        Wd = warndlg(['Please input ' ...
                            'an appropriate value for the optical wavelength.'], 'Warning');
                        centerFigure(Wd);
                    else
                        warning('An appropriate value for optical wavelength must be set.');
                    end
            end
            
            wavelength = this.lambda*1e-9;
            
            if isempty(this.lambda) || this.lambda<=0                
                this.x0 = 0;                
            else            
            this.x0 = 1e9*this.beta*wavelength/4/pi;
            end
            
            %Calculate spectrum calibration factor from sidebands with
            %sufficient SNR
            
            if isempty(this.lambda) || isempty(this.mod_freq) || this.lambda<=0                
                this.disp_cal = 0;
                this.disp_cal_err = 0;
            else            
            
                C = 0;
                m = 0;
                for k = 1:numel(peak_int)
                    ph = peak_int(k);
                    if ph/max(peak_int) > 1e-2 % Discard low amplitude sidebands from the calculation
                        if mod(sb_ind(k),2) ~= 0 %Odd sideband                       
                            Cp = (wavelength*besselj(sb_ind(k),this.beta))^2/8/(pi^2)/ph;
                            C = C + Cp;
                            m = m + 1;
                        else %Even sideband
                            Cp = (wavelength*besselj(sb_ind(k),this.beta))^2/8/(pi^2)/ph/(tan(pi*this.theta/180)^-2);
                            C = C + Cp;
                            m = m +1;
                        end
                    end                                                           
                end
                this.disp_cal = C/m;
                
                %Confidence interval for calibration factor
                if ~any(sb_ind == 1) || peak_norm(sb_ind == 1) < 1e-1
                    warning('Confidence interval has not been calculated; first order sideband has low amplitude.');
                    this.disp_cal_err = 0;
                else
                    this.disp_cal_err = abs((besselj(1,this.beta))*(besselj(0,this.beta) - besselj(2,this.beta))*...
                        dbeta*(wavelength^2)/(8*pi^2*peak_int(sb_ind == 1)));
                end
            end
        end 
            
        function clearPeakDisp(this)
            if ~isempty(this.PlottedPeaks)
                delete(this.PlottedPeaks)
            end
        end         
        
    end
    
    % Set and get methods
    methods
        function set.enable_cursor(this, val)
            if ~isempty(this.MinHeightCursor) && ...
                    isvalid(this.MinHeightCursor)
                this.MinHeightCursor.Line.Visible = val;
            end
        end
        
        function val = get.enable_cursor(this)
            if ~isempty(this.MinHeightCursor) && ...
                    isvalid(this.MinHeightCursor)
                val = strcmpi(this.MinHeightCursor.Line.Visible, 'on');
            else
                val = false;
            end
        end
        
        function val = get.min_peak_height(this)
            if this.enable_cursor
                val = this.MinHeightCursor.value;
            else
                val = this.min_peak_height;
            end
        end
    end
end

