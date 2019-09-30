% A generic class for programs based on Zurich Instruments UHFLI and MFLI
% lock-in amplifiers

classdef MyZiLockIn < MyInstrument
    
    properties (Access = public, SetObservable)
        
        % Used to establish connection with the instrument
        dev_serial = 'dev4090'
    end
    
    properties (GetAccess = public, SetAccess = protected, SetObservable)
        
        % This string gives the device name as it appears in 
        % the server's node tree. It is read out during the creation 
        % of session and is typically the same as dev_serial.
        dev_id
        
        % Device clock frequency, i.e. the number of timestamps per second
        clockbase
    end
    
    properties (Access = public, Dependent, Hidden)
        
        % Address is another alias for dev_serial which is kept for
        % compatibility with other instrument classes
        address
    end
    
    methods (Access = public)
        function createApiSession(this)
            
            % Check the ziDAQ MEX (DLL) and Utility functions can be found 
            % in Matlab's path.
            if ~(exist('ziDAQ', 'file') == 3) && ...
                    ~(exist('ziCreateAPISession', 'file') == 2)
                fprintf(['Failed to either find the ziDAQ mex file ' ...
                    'or ziDevices() utility.\n'])
                fprintf(['Please configure your path using the ziDAQ ' ...
                    'function ziAddPath().\n'])
                fprintf(['This can be found in the API subfolder of ' ...
                    'your LabOne installation.\n']);
                fprintf('On Windows this is typically:\n');
                fprintf(['C:\\Program Files\\Zurich Instruments' ...
                    '\\LabOne\\API\\MATLAB2012\\\n']);
                return
            end
            
            % Do not throw errors in the constructor to allow creating a
            % class instance when the physical device is disconnected
            try
                
                % Create an API session and connect to the correct Data  
                % Server. This is a high level function that uses  
                % ziDAQ('connect',.. and ziDAQ('connectDevice', ... when 
                % necessary
                apilevel = 6;
                [this.dev_id, ~] = ziCreateAPISession(this.dev_serial, ...
                    apilevel);

                % Read the divice clock frequency
                this.clockbase = ...
                    double(ziDAQ('getInt',['/',this.dev_id,'/clockbase']));
            catch ME
                warning(ME.message)
            end
        end
        
        function str = idn(this)
            DevProp = ziDAQ('discoveryGet', this.dev_id);
            str = this.dev_id;
            
            if isfield(DevProp, 'devicetype')
                str = [str,'; device type: ', DevProp.devicetype];
            end
            
            if isfield(DevProp, 'options')
                
                % Print options from the list as comma-separated values and
                % discard the last comma.
                opt_str = sprintf('%s,',DevProp.options{:});
                str = [str,'; options: ', opt_str(1:end-1)];
            end
            if isfield(DevProp, 'serverversion')
                str = [str,'; server version: ', DevProp.serverversion];
            end
            this.idn_str = str;
        end
    end
    
    methods (Access = protected)
        function createMetadata(this)
            createMetadata@MyInstrument(this);
            addObjProp(this.Metadata, this, 'clockbase', 'comment', ...
                ['Device clock frequency, i.e. the number of ', ...
                'timestamps per second']);
        end
    end
    
    methods
        
        % Alias for the device serial
        function val = get.address(this)
            val = this.dev_serial;
        end
        
        function set.address(this, val)
            this.dev_serial = val;
        end
    end
end

