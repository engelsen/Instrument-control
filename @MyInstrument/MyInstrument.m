% Generic class to implement communication with instruments 

classdef MyInstrument < dynamicprops & MyDataSource
    
    % Access for these variables is 'protected' and in addition
    % granted to MyClassParser in order to use construction parser 
    properties (GetAccess=public, SetAccess={?MyClassParser})     
        interface='';
        address=''; 
    end
    
    properties (Access=public)
        Device %Device communication object    
    end 
    
    properties (GetAccess=public, SetAccess=protected)
        idn_str=''; % identification string
    end
    
    properties (Constant=true)
        % Default parameters for device connection
        DEFAULT_INP_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_OUT_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_TIMEOUT = 10; % Timeout in s
    end
    
    events
        PropertyRead 
    end
    
    methods (Access=public)
        function this=MyInstrument(interface, address, varargin)
            P=MyClassParser();
            addRequired(P,'interface',@ischar);
            addRequired(P,'address',@ischar);
            addParameter(P,'name','',@ischar);
            processInputs(P, this, interface, address, varargin{:});
            
            % Create an empty trace
            this.Trace=MyTrace();
            
            % Create dummy device object that supports properties
            this.Device=struct();
            this.Device.Status='not connected';
            
            % Interface and address can correspond to an entry in the list
            % of local instruments. Read this entry in such case.
            if strcmpi(interface, 'instr_list')
                % load the InstrumentList structure
                InstrumentList = getLocalSettings('InstrumentList');
                % In this case 'address' is the instrument name in
                % the list
                instr_name = address;
                if ~isfield(InstrumentList, instr_name)
                    error('%s is not a field of InstrumentList',...
                        instr_name);
                end
                if ~isfield(InstrumentList.(instr_name), 'interface')
                    error(['InstrumentList entry ', instr_name,...
                        ' has no ''interface'' field']);
                else
                    this.interface = InstrumentList.(instr_name).interface;
                end
                if ~isfield(InstrumentList.(instr_name), 'address')
                    error(['InstrumentList entry ', instr_name,...
                        ' has no ''address'' field']);
                else
                    this.address = InstrumentList.(instr_name).address;
                end
                % Assign name automatically, but not overwrite if
                % already specified
                if isempty(this.name)
                    this.name = instr_name;
                end
            end
            
            % Connecting device creates a communication object, 
            % but does not attempt communication
            connectDevice(this);
        end
        
        function delete(this)         
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            try
                delete(this.Device);
            catch
            end
        end    
        
        %Triggers event for property read from device
        function triggerPropertyRead(this)
            notify(this,'PropertyRead')
        end
        
        % Read all the relevant instrument properties and return as a
        % MyMetadata object.
        % Dummy method that needs to be re-defined by a parent class
        function Hdr=readHeader(this)
            Hdr=MyMetadata();
            % Instrument name is a valid Matalb identifier as ensured by
            % its set method (see the superclass)
            addField(Hdr, this.name);
            % Add identification string as parameter
            addParam(Hdr, this.name, 'idn', this.idn_str);
        end
       
        
        %% Connect, open, configure, identificate and close the device
        % Connects to the device, explicit indication of interface and
        % address is for ability to handle instr_list as interface
        function connectDevice(this)
            int_list={'constructor','visa','tcpip','serial'};
            if ~ismember(lower(this.interface), int_list)
                warning(['Device is not connected, unknown interface ',...
                    this.interface,'. Valid interfaces are ',...
                    '''constructor'', ''visa'', ''tcpip'' and ''serial'''])
                return
            end
            try
                switch lower(this.interface)
                    % Use 'constructor' interface to connect device with
                    % more that one parameter, specifying its address
                    case 'constructor'
                        % in this case the 'address' is a command 
                        % (ObjectConstructorName), e.g. as returned by the 
                        % instrhwinfo, that creates communication object
                        % when executed
                        this.Device=eval(this.address);
                    case 'visa'
                        % visa brand is 'ni' by default
                        this.Device=visa('ni', this.address);
                    case 'tcpip'
                        % Works only with default socket. Use 'constructor'
                        % if socket or other options need to be specified
                        this.Device=tcpip(this.address);
                    case 'serial'
                        this.Device=serial(this.address);
                    otherwise
                        error('Unknown interface');
                end
                configureDeviceDefault(this);
            catch
                warning(['Device is not connected, ',...
                    'error while creating communication object.']);
            end
        end
        
        % Opens the device if it is not open. Does not throw error if
        % device is already open for communication with another object, but
        % tries to close existing connections instead.
        function openDevice(this)
            if ~isopen(this)
                try
                    fopen(this.Device);
                catch
                    % try to find and close all the devices with the same
                    % VISA resource name
                    try
                        instr_list=instrfind('RsrcName',this.Device.RsrcName);
                        fclose(instr_list);
                        fopen(this.Device);
                        warning('Multiple instrument objects of address %s exist',...
                            this.address);
                    catch
                        error('Could not open device')
                    end
                end
            end
        end
        
        % Closes the connection to the device
        function closeDevice(this)
            if isopen(this)
                fclose(this.Device);
            end
        end
        
        function configureDeviceDefault(this)
            dev_prop_list = properties(this.Device);
            if ismember('OutputBufferSize',dev_prop_list)
                this.Device.OutputBufferSize = this.DEFAULT_OUT_BUFF_SIZE;
            end
            if ismember('InputBufferSize',dev_prop_list)
                this.Device.InputBufferSize = this.DEFAULT_INP_BUFF_SIZE;
            end
            if ismember('Timeout',dev_prop_list)
                this.Device.Timeout = this.DEFAULT_TIMEOUT;
            end
        end
        
        % Checks if the connection to the device is open
        function bool=isopen(this)
            try
                bool=strcmp(this.Device.Status, 'open');
            catch
                warning('Cannot access device Status property');
                bool=false;
            end
        end
        
        %% Identification
        % Attempt communication and identification of the device
        function [str, msg]=idn(this)
            was_open=isopen(this);
            try
                openDevice(this);
                [str,~,msg]=query(this.Device,'*IDN?');
            catch ErrorMessage
                str='';
                msg=ErrorMessage.message;
            end   
            % Remove carriage return and new line symbols from the string
            newline_smb={sprintf('\n'),sprintf('\r')}; %#ok<SPRINTFN>
            str=replace(str, newline_smb,' ');
            this.idn_str=str;
            % Leave device in the state it was in the beginning
            if ~was_open
                try
                    closeDevice(this);
                catch
                end
            end
        end
        
    end
end