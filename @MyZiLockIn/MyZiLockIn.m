% A generic class for programs based on Zurich Instruments UHFLI and MFLI
% lock-in amplifiers

classdef MyZiLockIn < MyInstrument
    
    properties (GetAccess = public, ...
            SetAccess = {?MyClassParser, ?MyZiLockIn}, SetObservable)
        
        dev_serial = 'dev4090'
        
        % The string that specifies the device name as appears 
        % in the server's node tree. Can be the same as dev_serial.
        dev_id
        
        % Device clock frequency, i.e. the number of timestamps per second
        clockbase
    end
    
    methods (Access = public)
        function this = MyZiLockIn(varargin)    
            P = MyClassParser(this);
            addParameter(P, 'address', '', @ischar);
            processInputs(P, this, varargin{:});
            
            % address is another alias for dev_serial
            if ~ismember('address', P.UsingDefaults)
                this.dev_serial = P.Results.address;
            end
            
            % Check the ziDAQ MEX (DLL) and Utility functions can be found 
            % in Matlab's path.
            if ~(exist('ziDAQ', 'file') == 3) && ...
                    ~(exist('ziCreateAPISession', 'file') == 2)
                fprintf('Failed to either find the ziDAQ mex file or ziDevices() utility.\n')
                fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
                fprintf('This can be found in the API subfolder of your LabOne installation.\n');
                fprintf('On Windows this is typically:\n');
                fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
                return
            end
            
            % Do not throw errors in the constructor to allow creating an
            % instance when the physical device is disconnected
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
end

