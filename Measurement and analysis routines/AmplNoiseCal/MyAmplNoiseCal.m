% Routine for the calibration of Relative Intensity Noise (RIN) spectrum 
% using a calibration tone with known amplitude modulation depth, alpha, 
% defined in the following expression for the complex amplitude:
%
% E_0(t) = A*(1+\alpha \cos(\Omega_{cal} t))

classdef MyAmplNoiseCal < MyAnalysisRoutine
    
    properties (Access = public, SetObservable = true)
        
        % Thermomechanical spectrum
        Data            MyTrace
        
        % RIN spectrum
        AmplSpectrum    MyTrace
        
        % Cursors for the selection of calibration tone
        CalCursors      MyCursor
        cal_range = [0, 0]
        
        % Amplitude modulation depth of the calibration tone, supplied
        % externally
        alpha = 0.1
    end
    
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        Axes
        Gui
        
        % Frequency of the calibration tone, found in the cal_range 
        cal_freq
        
        % Conversion factor between S_V and RIN defined such that
        % RIN = cf*S_V
        cf = 1
    end
    
    methods (Access = public)
        function this = MyAmplNoiseCal(varargin)
            p = inputParser();
            addParameter(p, 'Data', MyTrace());
            addParameter(p, 'Axes', [], @isaxes);
            addParameter(p, 'enable_gui', true, @islogical);
            parse(p, varargin{:});
            
            this.Data = p.Results.Data;
            this.Axes = p.Results.Axes;
            
            this.AmplSpectrum = MyTrace();

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
                this.Gui = GuiAmplNoiseCal(this);
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
            
            % Calculate area under the calibration tone peak
            area = integrate(this.Data, cr(1), cr(2));
            
            % Average square of relative intensity excursions due to the 
            % calibration tone 
            vSqCt = 2*this.alpha^2;
            
            this.cf = vSqCt/area;
        end
        
        % Convert data using pre-calculated conversion factor
        function convertSpectrum(this)
            if isempty(this.Data) || isDataEmpty(this.Data)
                warning('Data is empty');
                return
            end
            
            this.AmplSpectrum.x = this.Data.x;
            this.AmplSpectrum.y = this.Data.y*this.cf;
            
            this.AmplSpectrum.name_x = this.Data.name_x;
            this.AmplSpectrum.unit_x = 'Hz';
            
            this.AmplSpectrum.name_y = 'RIN';
            this.AmplSpectrum.unit_y = '1/Hz';
            
            % Update metadata
            this.AmplSpectrum.UserMetadata = createMetadata(this);

            triggerNewAnalysisTrace(this, ...
                'Trace', copy(this.AmplSpectrum), 'analysis_type', 'rin');
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
            
            addParam(Mdt, 'alpha', this.alpha, ...
                'comment', 'Amplitude modulation depth');
            addParam(Mdt, 'cal_freq', this.cal_freq, ...
                'comment', ['Calibration tone frequency (' ...
                this.Data.unit_x ')']);
            addParam(Mdt, 'cf', this.cf, ...
                'comment', 'Conversion factor RIN = cf*S_V');
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
    end
end

