% Calibration routine for the vacuum optomechanical coupling rate g0 

classdef Myg0Cal < MyAnalysisRoutine
    properties (Access = public, SetObservable = true)
        
        % Thermomechanical spectrum
        Data            MyTrace
        
        % Cursors for the selection of calibration tone
        RefCursors      MyCursor
        
        % Cursors for the integration of thermomechanical noise
        MechCursors     MyCursor
        
        % Fitting routine used in the method is 'fit'
        LorFit          MyLorenzianFit
        
        % method of finding the area under the mechanical noise peak, 
        % integration or fit
        method = 'integration'
        
        % Calibration parameters set by the user
        beta    % Phase modulation depth of the reference tone
        T       % Temperature (K)
        
        % Correction for dynamic backaction. Requires 'fit' method 
        % and reference quality factor. 
        correct_dba = false 
        ref_Q
        
        % Calibration result, g0l = g0/2pi
        g0l
    end
    
    properties (GetAccess = public, SetAccess = protected)
        Gui
        
        % Parameters of the fitted mechanical Lorentzian
        Q=
        lw
        freq
    end
    
    properties (Access = protected)
        cal_tone_freq
        
        Psl     % listener to the PostSet event of 'method' property
    end
    
    methods (Access = public)
        function this = Myg0Cal(varargin)
            P = MyClassParser(this);
            addParameter(P, 'Axes', @isaxes);
            addParameter(P, 'enable_gui', @islogical);
            processInputs(this);
            
            % Protected properties of the class must be assigned explicitly
            % while the public ones were assigned in processInputs
            this.Axes = p.Results.Axes;

            if ~isempty(this.Axes)
                
                % Add two sets of vertical cursors for the selection of
                % integration ranges
                xlim = this.Axes.XLim;
                x1 = xlim(1)+0.2*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.2*(xlim(2)-xlim(1));
                
                this.RefCursors = ...
                    [MyCursor(this.Axes, x1, 'orientation', 'vertical', ...
                    'Label','Ref 1', 'Color', [0, 0, 0.6]), ...
                    MyCursor(this.Axes, x2, 'orientation', 'vertical', ...
                    'Label','Ref 2', 'Color', [0, 0, 0.6])];
                
                x1 = xlim(1)+0.1*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.1*(xlim(2)-xlim(1));
                
                this.MechCursors = ...
                    [MyCursor(this.Axes, x1, 'orientation', 'vertical', ...
                    'Label','Mech 1', 'Color', [0.6, 0, 0]), ...
                    MyCursor(this.Axes, x2, 'orientation', 'vertical', ...
                    'Label','Mech 2', 'Color', [0.6, 0, 0])];
            end
            
            % This listener handles the switching between the analysis
            % methods
            this.Psl = addListener(this, 'method', 'PostSet', ...
                @(~,~)updateMethod(this));
            updateMethod(this);
            
            % Gui is created right before the construction of object 
            % is over 
            if p.Results.enable_gui
                this.Gui = Guig0Cal(this);
            end
        end
        
        function delete(this)
            if ~isempty(this.Psl)
                delete(this.Psl);
            end
            if ~isempty(this.RefCursors)
                delete(this.RefCursors);
            end
            if ~isempty(this.MechCursors)
                delete(this.MechCursors);
            end
        end
        
        % Calculate g0
        function calcg0(this)
            
            xmin = ;
            xmax = ;
            
            % Calculate area under the calibration tone peak
            cal_tone_area = integrate(this.Data, xmin, xmax);
            
            if isequal(this.method, 'integration')
            elseif isequal(this.method, 'fit')
            end
            
            % Boltzmann and Planck constants
            k_b = 1.3806e-23;     % J/K
            h = 6.62607e-34;      % m^2*kg/s
            
            % Equilibrium thermal occupation of the oscillator
            n_th = k_b*this.T/(h*this.mech_freq);
            
            % Calculate g0
            this.g0l = this.beta*this.cal_tone_freq* ...
                sqrt(mech_area/(cal_tone_area*4*n_th));
        end
    end
    
    methods (Access = protected)
        
        % Initialize a new fit object if it was not created yet and if the
        % method is 'fit'
        function updateMethod(this)
            if isequal(this.method, 'fit')
                
                % Make sure that the fit object is initialized
                if isempty(this.LorFit) || ~isvalid(this.LorFit)
                    this.LorFit = MyLorenzianFit('Axes', this.Axes, ...
                        'Data', this.Data, 'enable_range_cursors', true);
                end
                
                % Hide the integration cursors
                set(this.MechCursors.Visible, 'off');
                
                % Show the fit range cursors and set them to the same
                % position as the integration cursors
                this.LorFit.enable_range_cursors = true;
                set(this.LorFit.RangeCursors.value,this.MechCursors.value);
                
                genInitParams(this.LorFit);
            elseif isequal(this.method, 'integration')
                
                % Show the integration cursors
                set(this.MechCursors.Visible, 'on');
                
                % Make sure that the fit object is initialized
                if ~isempty(this.LorFit) && isvalid(this.LorFit)
                    
                    % Set integration cursors to the same position as fit
                    % range cursors
                    set(this.MechCursors.value, ...
                        this.LorFit.RangeCursors.value);
                    
                    % Hide the fit range cursors and delete the fit curve
                    this.LorFit.enable_range_cursors = false;
                    clearFit(this.LorFit);
                end
            end
        end
        
        % Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            lw = this.param_vals(2); 
            freq = this.param_vals(3); 
            
            this.lw = lw;                % Linewidth in Hz
            this.freq = freq/1e6;        % Frequency in MHz
            this.Q = (freq/lw)/1e6;      % Q in millions  

        end
        
        function createUserParamList(this)
            addUserParam(this, 'lw', 'title', 'Linewidth (Hz)', ...
                'editable', 'off');
            addUserParam(this, 'freq', 'title', 'Frequency (MHz)', ...
                'editable', 'off');
            addUserParam(this, 'Q', 'title', 'Qualify Factor (x10^6)', ...
                'editable', 'off');
            
            % Parameters inputed externally
            addUserParam(this, 'beta', ...
                'title',        'Modulation depth \beta', ...
                'editable',     'on', ...
                'default',      0.1);
            addUserParam(this, 'T', ...
                'title',        'Temperature (K)', ...
                'editable',     'on', ...
                'default',      300);
            addUserParam(this, 'refQ', 'title', ...
                'Independently measured qualify Factor (x10^6)', ...
                'editable',     'on', ...
                'default',      1);
            
            % Calibrated values
            addUserParam(this, 'g0_int', 'title', 'g_0 from integration', ...
                'editable', 'off');
            addUserParam(this, 'g0_fit', 'title', 'g_0 from fit', ...
                'editable', 'off');
        end
    end
    
    methods
        function set.method(this, val)
            assert(ischar(val), ...
                'Value assigned as ''method'' must be a character string')
            
            val = lower(val);
            assert(isequal(val, 'integration') || isequal(val, 'fit'), ...
                '''method'' must be ''integration'' or ''fit''')
            
            if ~isequal(this.method, val)
                
                % We only set the property when its value has actually
                % changes in order to prevent redundant executions of the
                % post set listener
                this.method = val;
            end
        end
    end
end
