% Routine for the calibration of beta-factor, characterizing the phase 
% modulation of light, using heterodyne signal spectrum.
%
% Beta is defined in the following expression for phase-modulated complex 
% amplitude of light:
%
% E_0(t) = A*Exp(-i\beta \cos(\Omega_{cal} t))

classdef MyPhaseModCal < MyAnalysisRoutine
    
    properties (Access = public, SetObservable = true)
        Data    MyTrace
        
        % Minimum thereshold for peak search. If MinHeightCursor exists, it
        % has priority over the programmatically set value.
        min_peak_height     double   
        
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
    end
    
    properties (Access = protected)
        
        % Line that displays the positions of peaks found
        PlottedPeaks 
    end
    
    methods (Access = public)
        function this = MyPhaseModCal(varargin)
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
                pos = min(ylim(1)+0.1*(ylim(2)-ylim(1)), 10*ylim(1));
                
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
                this.Gui = GuiPhaseModCal(this);
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
            
            % Find the central peak, which is not necessarily the highest
            mean_freq = sum(peak_x.*peak_y)/sum(peak_y);
            [~, cent_ind] = min(abs(peak_x-mean_freq));
            
            % Take the integration width to be a few times the width of the
            % central peak.
            int_w = 6*peak_w(cent_ind);
            
            % Check if the peaks are rougly equally spaced harmonics, if
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
            
            % Delete the peaks that do not appear at the expected
            % frequencies of harmonics of the modulation frequency
            scaled_peak_x = (peak_x - peak_x(cent_ind))/mod_f;
            sb_ind = cent_ind;
            for i = 1:ceil(n_peaks/2)

                % Iterate over the sideband index i and find pairs of
                % sidebands
                [err_p, ind_p] = min(abs(scaled_peak_x - i));
                [err_m, ind_m] = min(abs(scaled_peak_x + i));

                if (err_p/i < mod_peak_tol) && (err_m/i < mod_peak_tol) 

                    % Add the found indices to the list of sideband 
                    % peak indices
                    sb_ind = [ind_m, sb_ind, ind_p]; %#ok<AGROW>
                else
                    break
                end
            end

            % Out of all peaks select sideband peaks that appear in pairs 
            peak_y = peak_y(sb_ind); 
            peak_x = peak_x(sb_ind);
            
            n_peaks = length(peak_y);
            assert(n_peaks >= 3, ['Less than 3 peaks are found. ' ...
                'Phase modulation depth cannot be calculated.'])
            
            % Re-calculate the modulation frequency
            mod_f = (peak_x(end)-peak_x(1))/(n_peaks-1);
            
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
            peak_int = peak_int/max(peak_int);
            
            % Find beta value by fitting           
            Ft = fittype('a*besselj(n, beta)^2', 'independent', 'n', ...
                'coefficients', {'a', 'beta'});
            Opts = fitoptions('Method', 'NonLinearLeastSquares',...
                'StartPoint',   [1, 0.1],...
                'MaxFunEvals',  2000,...
                'MaxIter',      2000,...
                'TolFun',       1e-10,...
                'TolX',         1e-10);
            
            peak_ord = -floor(n_peaks/2):floor(n_peaks/2);
            FitResult = fit(peak_ord(:), peak_int(:), Ft, Opts);
            
            % Store the result in class variables
            this.beta = abs(FitResult.beta);
            this.mod_freq = mod_f;
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

