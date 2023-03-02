% Routine for the calibration of frequency noise spectrum using a
% calibration tone with known phase modulation depth, beta, defined as
% follows:
%
% E_0(t) = A*Exp(-i\beta \cos(\Omega_{cal} t))

classdef MyFreqNoiseCal < MyAnalysisRoutine

    properties (Access = public, SetObservable = true)
        
        % Thermomechanical spectrum
        Data            MyTrace
        
        % Spectrum, calibrated in frequency units. It can be
        % S_\omega
        % S_f = S_\omega/(2pi)^2
        % sqrt(S_f)
        FreqSpectrum    MyTrace
        
        % The type of calculated frequency spectrum, 
        % S_\omega, S_f or sqrt(S_f) 
        spectrum_type = 'S_f' 
        
        % Cursors for the selection of calibration tone
        CalCursors      MyCursor
        cal_range = [0, 0]
        
        % Phase modulation depth of the calibration tone, supplied
        % externally
        beta = 0.1
    end
    
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        Axes
        Gui
        
        % Frequency of the calibration tone, found in the cal_range 
        cal_freq
        
        % Conversion factor between S_V and S_\omega defined such that
        % S_\omega = cf*S_V
        cf = 1
    end
    
    methods (Access = public)
        function this = MyFreqNoiseCal(varargin)
            p = inputParser();
            addParameter(p, 'Data', MyTrace());
            addParameter(p, 'Axes', [], @isaxes);
            addParameter(p, 'enable_gui', true, @islogical);
            parse(p, varargin{:});
            
            this.Data = p.Results.Data;
            this.Axes = p.Results.Axes;
            
            this.FreqSpectrum = MyTrace();

            if ~isempty(this.Axes)
                
                % Add two sets of vertical cursors for the selection of
                % integration ranges
                xlim = this.Axes.XLim;
                x1 = xlim(1)+0.4*(xlim(2)-xlim(1));
                x2 = xlim(1)+0.45*(xlim(2)-xlim(1));
                
                this.CalCursors = ...
                    [MyCursor(this.Axes, ...
                    'orientation', 'vertical', 'position', x1, ...
                    'Label','Cal 1', 'Color', [0, 0, 0.6]), ...
                    MyCursor(this.Axes, ...
                    'orientation', 'vertical', 'position', x2, ...
                    'Label','Cal 2', 'Color', [0, 0, 0.6])];
            end
            
            % Gui is created right before the construction of object 
            % is over 
            if p.Results.enable_gui
                this.Gui = GuiFreqNoiseCal(this);
            end
        end
        
        function delete(this)
            if ~isempty(this.CalCursors)
                delete(this.CalCursors);
            end
        end
        
        % Calculates cf
        function calcConvFactor(this)
            if isempty(this.Data) || isDataEmpty(this.Data)
                warning('Data is empty');
                return
            end
            
            cr = this.cal_range;
            
            % Find the frequency of calibration tone
            ind = (this.Data.x>cr(1) & this.Data.x<=cr(2));
            freq = sum(this.Data.x(ind) .* this.Data.y(ind))/ ...
                sum(this.Data.y(ind));
            
            this.cal_freq = freq;
            
            [cal_psd, ~] = max(this.Data.y(ind));
            % Calculate area under the calibration tone peak
            if 0
                % previous way of calculating cal tone power, by integral
                % using rbw = span/nop. In actual measurement RSA could set
                % a different rbw instead, and could result also in leakage
                % of power to nearby points.
                area = integrate(this.Data, cr(1), cr(2));
            else
                % directly readout the actual rbw from the RSA, and use
                % peak * rbw to calculate cal tone power, preventing
                % leakage to nearby points. This assumes rbw >> linewidth
                % of cal tone.
                if evalin('base',"exist('RSA5103','var') == 1")
                    cal_rbw = evalin('base',"RSA5103.rbw_act");
                elseif evalin('base',"exist('RSA5106','var') == 1")
                    cal_rbw = evalin('base',"RSA5106.rbw_act");
                else
                    cal_rbw = this.Data.x(ind(2)) - this.Data.x(ind(1));
                    disp("The act_rbw is not used, span/nop is used instead. Please open the RSA gui for a more accurate rbw.");
                end
                % should be actual rbw from RSA, but for no access to it will
                % use the span/nop instead. Mismatch at 50% with 1e4 point
                % traces, coincide with other nop settings.
                % could be possible
                area = cal_psd * cal_rbw;
            end
            
            % Average square of frequency excursions due to calibration 
            % tone 
            vSqCt = this.beta^2*(2*pi*freq)^2/2;
            
            this.cf = vSqCt/area;
        end
        
        function convertSpectrum(this)
            if isempty(this.Data) || isDataEmpty(this.Data)
                warning('Data is empty');
                return
            end
            
            this.FreqSpectrum.x = this.Data.x;
            this.FreqSpectrum.name_x = this.Data.name_x;
            this.FreqSpectrum.unit_x = 'Hz';
            
            switch this.spectrum_type
                case 'S_\omega'
                    this.FreqSpectrum.name_y = '$S_{\omega}$';
                    this.FreqSpectrum.unit_y = 'rad$^2$/Hz';
                    
                    this.FreqSpectrum.y = this.Data.y*this.cf;
                case 'S_f'
                    this.FreqSpectrum.name_y = '$S_{\omega}/(2\pi)^2$';
                    this.FreqSpectrum.unit_y = 'Hz$^2$/Hz';
                    
                    this.FreqSpectrum.y = ...
                        this.Data.y*this.cf/(2*pi)^2;
                case 'sqrt(S_f)'
                    this.FreqSpectrum.name_y ='$\sqrt{S_{\omega}}/(2\pi)$';
                    this.FreqSpectrum.unit_y ='Hz/$\sqrt{\mathrm{Hz}}$';
                    
                    this.FreqSpectrum.y = ...
                        sqrt(this.Data.y*this.cf)/(2*pi);
                otherwise
                    error(['Unknown frequency spectrum type ' ...
                        this.spectrum_type])
            end
            
            % Update metadata
            this.FreqSpectrum.UserMetadata = createMetadata(this);

            triggerNewProcessedData(this, 'traces', ...
                {copy(this.FreqSpectrum)}, 'trace_tags', {'_freq_noise'});
        end
    end
    
    methods (Access = protected)
        function Mdt = createMetadata(this)
            Mdt = MyMetadata('title', 'CalibrationParameters');
            
            if ~isempty(this.Data.file_name)
                
                % If data file has name, indicate it 
                addParam(Mdt, 'source', this.Data.file_name, ...
                    'comment', 'File containing raw data');
            end
            
            addParam(Mdt, 'spectrum_type', this.spectrum_type);
            addParam(Mdt, 'beta', this.beta, ...
                'comment', 'Phase modulation depth');
            addParam(Mdt, 'cal_freq', this.cal_freq, ...
                'comment', ['Calibration tone frequency (' ...
                this.Data.unit_x ')']);
            addParam(Mdt, 'cf', this.cf, ...
                'comment', 'Conversion factor S_\omega = cf*S_V');
        end
    end
    
    % Set and get methods
    methods
        
        % Get the integration range for the calibration tone
        function val = get.cal_range(this)
            if ~isempty(this.CalCursors) && all(isvalid(this.CalCursors))
                
                % If cursors exist, return the range between the
                % cursors
                xmin = min(this.CalCursors.value);
                xmax = max(this.CalCursors.value);
                
                val = [xmin, xmax];
            else
                
                % Otherwise the value can be set programmatically
                val = this.cal_range;
            end
        end
        
        function set.spectrum_type(this, val)
            val_list = {'S_\omega', 'S_f', 'sqrt(S_f)'};
            
            assert(ismember(val, val_list), ['The value of ' ...
                'spectrum_type must be one of the following: ' ...
                var2str(val_list)])
            this.spectrum_type = val;
        end
    end
end

