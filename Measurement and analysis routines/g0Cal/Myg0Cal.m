% Calibration routine for the vacuum optomechanical coupling rate g0 

classdef Myg0Cal < MyAnalysisRoutine & MyGuiCont
    
    properties (Access = public, SetObservable)
        
        % Thermomechanical spectrum
        Data            MyTrace
        
        % Cursors for the selection of calibration tone
        CalCursors      MyCursor
        cal_range = [0, 0]
        
        % Cursors for the integration of thermomechanical noise
        MechCursors     MyCursor
        mech_range = [0, 0]
        
        % Fitting routine used in the method is 'fit'
        LorFit          MyLorentzianFit
        
        % method of finding the area under the mechanical noise peak, 
        % integration or fit
        method = 'integration'
        
        % Calibration parameters set by the user
        beta = 0      % Phase modulation depth of the reference tone
        T = 300       % Temperature (K)
        
        % Correction for dynamic backaction. Requires 'fit' method 
        % and reference quality factor. 
        correct_dba = false 
        ref_Q = 0
    end
    
    properties (GetAccess = public, SetAccess = protected, SetObservable)
        Axes = matlab.graphics.axis.Axes.empty()
        
        % Parameters of the fitted mechanical Lorentzian
        Q = 0
        lw = 0
        freq = 0
        
        % Calibration result, g0l = g0/2pi
        g0l = 0
    end
    
    properties (Access = protected)
        Psl     % listener to the PostSet event of 'method' property
    end
    
    methods (Access = public)
        function this = Myg0Cal(varargin)
            P = MyClassParser(this);
            addParameter(P, 'enable_gui', true, @islogical);
            processInputs(P, this, varargin{:});

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
                
                x1 = xlim(2)-0.45*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.4*(xlim(2)-xlim(1));
                
                this.MechCursors = ...
                    [MyCursor(this.Axes, ...
                    'orientation', 'vertical', 'position', x1, ...
                    'Label','Mech 1', 'Color', [0.6, 0, 0]), ...
                    MyCursor(this.Axes, ...
                    'orientation', 'vertical', 'position', x2, ...
                    'Label','Mech 2', 'Color', [0.6, 0, 0])];
            end
            
            % This listener handles the initialization of fitting routine
            % when the method is switched to 'fit' for the first time 
            this.Psl = addlistener(this, 'method', 'PostSet', ...
                @(~,~)initFit(this));
            
            % Gui is created right before the construction of object 
            % is over 
            if P.Results.enable_gui
                createGui(this);
            end
        end
        
        function delete(this)
            if ~isempty(this.Psl)
                delete(this.Psl);
            end
            if ~isempty(this.CalCursors)
                delete(this.CalCursors);
            end
            if ~isempty(this.MechCursors)
                delete(this.MechCursors);
            end
            if ~isempty(this.LorFit)
                delete(this.LorFit)
            end
        end
        
        % Calculate g0
        function calcg0(this)
            if isempty(this.Data) || isDataEmpty(this.Data)
                warning('Data is empty');
                return
            end
            
            if this.beta <= 0
                warning('Phase modulation depth beta must be specified')
                return
            end
            
            cr = this.cal_range;
            
            % Find the frequency of calibration tone
            ind = (this.Data.x>cr(1) & this.Data.x<=cr(2));
            cal_tone_freq = sum(this.Data.x(ind) .* this.Data.y(ind))/ ...
                sum(this.Data.y(ind));
            
            % Calculate area under the calibration tone peak
            cal_tone_area = integrate(this.Data, cr(1), cr(2));
            
            mr = this.mech_range;
            
            if isequal(this.method, 'integration')
                mech_area = integrate(this.Data, mr(1), mr(2));
                
                % Estimate mechanical frequency
                ind = (this.Data.x>mr(1) & this.Data.x<=mr(2));
                this.freq = sum(this.Data.x(ind) .* this.Data.y(ind))/ ...
                    sum(this.Data.y(ind));
            elseif isequal(this.method, 'fit')
                
                % Select data within the mechanics range
                ind = (this.Data.x>mr(1) & this.Data.x<=mr(2));
                this.LorFit.Data.x = this.Data.x(ind);
                this.LorFit.Data.y = this.Data.y(ind);
                
                fitTrace(this.LorFit);
                
                % Extract fitted parameters
                this.lw = this.LorFit.param_vals(2);     % Linewidth in Hz
                this.freq = this.LorFit.param_vals(3);   % Frequency in Hz
                this.Q = (this.freq/this.lw);            % Q in millions  
                
                % Our Lorentzian is normalized such that the area under 
                % the curve is equal to the amplitude parameter
                mech_area = this.LorFit.param_vals(1);
                
                if this.correct_dba
                    
                    % Apply correction for the cooling or amplification 
                    % of mechanical motion by dynamic backaction
                    mech_area = mech_area*this.ref_Q/this.Q;
                end
            end
            
            % Boltzmann and Planck constants
            k_b = 1.3806e-23;     % J/K
            h = 6.62607e-34;      % m^2*kg/s
            
            % Equilibrium thermal occupation of the oscillator
            n_th = k_b*this.T/(h*this.freq);
            
            % Calculate g0
            this.g0l = this.beta*cal_tone_freq* ...
                sqrt(mech_area/(cal_tone_area*4*n_th));
        end
    end
    
    methods (Access = protected)
        
        % Initialize a new fit object if it was not created yet and if the
        % method is 'fit'
        function initFit(this)
            if isequal(this.method, 'fit')
                
                % Make sure that the fit object is initialized
                if isempty(this.LorFit) || ~isvalid(this.LorFit)
                    
                    % Select data within the mechanics range
                    ind = (this.Data.x>this.mech_range(1) & ...
                        this.Data.x<=this.mech_range(2));

                    this.LorFit = MyLorentzianFit('Axes', this.Axes, ...
                        'x', this.Data.x(ind), 'y', this.Data.y(ind), ...
                        'enable_range_cursors', false, ...
                        'enable_gui', false);
                end
                
                genInitParams(this.LorFit);
            else
                if ~isempty(this.LorFit) && isvalid(this.LorFit)
                    
                    % Remove the fit curve from the plot
                    clearFit(this.LorFit);
                end
            end
        end
    end
    
    methods
        function set.method(this, val)
            assert(ischar(val), ...
                'Value assigned as ''method'' must be a character string')
            
            val = lower(val);
            assert(isequal(val, 'integration') || isequal(val, 'fit'), ...
                '''method'' must be ''integration'' or ''fit''')
            
            this.method = val;
        end
        
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
        
        % Get the range for the mechanical peak
        function val = get.mech_range(this)
            if ~isempty(this.MechCursors) && all(isvalid(this.MechCursors))
                
                % If cursors exist, return the range between the
                % cursors
                xmin = min(this.MechCursors.value);
                xmax = max(this.MechCursors.value);
                
                val = [xmin, xmax];
            else
                
                % Otherwise the value can be set programmatically
                val = this.mech_range;
            end
        end
    end
end
