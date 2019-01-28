% A generic class for programs based on Zurich Instruments UHFLI and MFLI
% lock-in amplifiers

classdef MyZiLi < handle
    
    properties (GetAccess=public, SetAccess={?MyClassParser, ?MyZiLi})
        dev_serial='dev4090'
        
        % The string that specifies the device name as appears 
        % in the server's node tree. Can be the same as dev_serial.
        dev_id
        
        % Device information string containing the data returned by  
        % ziDAQ('discoveryGet', ... 
        idn_str
        
        % Device clock frequency, i.e. the number of timestamps per second
        clockbase
    end
    
    events
        NewSetting          % Device settings changed
    end
    
    methods
        function this=MyZiLi(dev_serial, varargin)
            
            % Check the ziDAQ MEX (DLL) and Utility functions can be found in Matlab's path.
            if ~(exist('ziDAQ', 'file') == 3) && ~(exist('ziCreateAPISession', 'file') == 2)
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
                apilevel=6;
                [this.dev_id,~]=ziCreateAPISession(dev_serial, apilevel);

                % Read the divice clock frequency
                this.clockbase = ...
                    double(ziDAQ('getInt',['/',this.dev_id,'/clockbase']));
            catch ME
                warning(ME.message)
            end

        end
        
        function str=idn(this)
            DevProp=ziDAQ('discoveryGet', this.dev_id);
            str=this.dev_id;
            if isfield(DevProp, 'devicetype')
                str=[str,'; device type: ', DevProp.devicetype];
            end
            if isfield(DevProp, 'options')
                % Print options from the list as comma-separated values and
                % discard the last comma.
                opt_str=sprintf('%s,',DevProp.options{:});
                str=[str,'; options: ', opt_str(1:end-1)];
            end
            if isfield(DevProp, 'serverversion')
                str=[str,'; server version: ', DevProp.serverversion];
            end
            this.idn_str=str;
        end
        
        function Hdr=readHeader(this)
            Hdr=MyMetadata();
            % name is always a valid variable as ensured by its set method
            addField(Hdr, this.name);
            % Instrument identification 
            addParam(Hdr, this.name, 'idn', this.idn_str);
            addObjProp(Hdr, this, 'clockbase', 'comment', ...
                ['Device clock frequency, i.e. the number of ', ...
                'timestamps per second']);
        end

    end
end

