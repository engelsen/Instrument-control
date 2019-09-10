% Routine for the calibration of amplitude modulation depth, alpha, 
% using heterodyne signal spectrum.
%
% Alpha is defined in the following expression for amplitude-modulated 
% complex amplitude of light:
%
% E_0(t) = A*(1+\alpha \cos(\Omega_{cal} t))

classdef MyAmplModCal < MyAnalysisRoutine
    
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
        
        alpha = 0        % Phase modulation depth
    end
    
    properties (Access = protected)
        
        % Line that displays the positions of peaks found
        PlottedPeaks 
    end
    
    methods (Access = public)
        function this = MyAmplModCal(varargin)
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
                this.Gui = GuiAmplModCal(this);
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
        function calcAlpha(this)
            min_y = this.min_peak_height;
            
            % Find peaks above the given threshold
            % Returned values: [y, x, widths, prominences]
            [peak_y, peak_x, peak_w, ~] = findpeaks( ...
                this.Data.y, this.Data.x, 'MinPeakHeight', min_y);
            
            n_peaks = length(peak_y);
            
            assert(n_peaks >= 3, ['Less than 3 peaks are found in '...
                'the data with given threshold (' num2str(min_y) '). ' ...
                'Amplitude modulation depth cannot be calculated.'])
            
            % Find the central peak, which is not necessarily the highest
            mean_freq = sum(peak_x.*peak_y)/sum(peak_y);
            [~, cent_ind] = min(abs(peak_x-mean_freq));
            
            % Take the integration width to be a few times the width of the
            % central peak.
            int_w = 6*peak_w(cent_ind);
            
            if isempty(this.mod_freq) || this.mod_freq<=0
                
                % If an approximate value of modulation frequency is not 
                % known, take the central peak plus another two highest 
                % peaks of the spectrum
                [~, sort_ind] = sort(peak_y, 'descend');
                
                % Remove the central peak index from the set
                sort_ind = setdiff(sort_ind, cent_ind, 'stable');
                
                pm_sb_ind = sort(sort_ind(1:2), 'ascend');
                
                sb_ind = [pm_sb_ind(1), cent_ind, pm_sb_ind(2)];
            else
                
                % Select two sidebands spaced by one modulation frequency
                % from the central peak
                mod_f = this.mod_freq;
                scaled_peak_x = (peak_x - peak_x(cent_ind))/mod_f;
                
                % Find sidebands
                [err_p, ind_p] = min(abs(scaled_peak_x - 1));
                [err_m, ind_m] = min(abs(scaled_peak_x + 1));
                
                % Specify the tolerance to the mismatch between the   
                % frequencies of the found peaks and pre-defined mod_freq 
                mod_peak_tol = 0.1;
                
                if (err_p < mod_peak_tol) && (err_m < mod_peak_tol) 

                    % Add the found indices to the list of sideband 
                    % peak indices
                    sb_ind = [ind_m, cent_ind, ind_p];
                else
                    
                    % Prompt user to specify approximate modulation
                    % frequency. Show warning dialog if running in a gui
                    % mode or output warning in the command line otherwise.  
                    msg = ['Cannot identify modulation sidebands. ' ...
                        'Please check the approximate value of ' ...
                        'modulation frequency and try again.'];
                        
                    if ~isempty(this.Gui)
                        Wd = warndlg(msg, 'Warning');
                        centerFigure(Wd);
                    else
                        warning(msg);
                    end
                end
            end
            
            peak_x = peak_x(sb_ind);
            peak_y = peak_y(sb_ind);
            
            mod_f = (peak_x(3)-peak_x(1))/2;
            
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
            n_peaks = 3;
            peak_int = zeros(1, n_peaks);
            for i = 1:n_peaks
                peak_int(i) = integrate(this.Data, peak_x(i)-int_w/2, ...
                    peak_x(i)+int_w/2);
            end
            
            % Calculate alpha
            this.alpha = sqrt(2*(peak_int(1)+peak_int(3))/peak_int(2));
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
        
        % The value of min_peak_hight is taken from the cursor if it is
        % enabled, or it can be set programmatically if there is no cursor
        function val = get.min_peak_height(this)
            if this.enable_cursor
                val = this.MinHeightCursor.value;
            else
                val = this.min_peak_height;
            end
        end
    end
end

