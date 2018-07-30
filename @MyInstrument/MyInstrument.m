classdef MyInstrument < dynamicprops & MyInputHandler
    
    properties (Access=public)
        name='';
        interface='';
        address='';
        visa_brand='ni';
    end 
    
    properties (SetAccess=protected, GetAccess=public)
        %Contains the device object. struct() is a dummy, as Device 
        %needs to always support properties for consistency.
        Device=struct();
        %Trace object for storing data
        Trace=MyTrace();
    end
    
    properties (Constant=true)
        % Default parameters for device connection
        DEFAULT_INP_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_OUT_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_TIMEOUT = 10; % Timeout in s
    end
    
    events
        NewData;
    end
    
    methods (Access=protected)
        % This function is overloaded to add more parameters to the parser 
        function p = createConstructionParser(this)
            p=inputParser();
            % Ignore unmatched parameters
            p.KeepUnmatched = true;
            addRequired(p,'interface',@ischar);
            addRequired(p,'address',@ischar);
            addParameter(p,'name','',@ischar);
            addParameter(p,'visa_brand',this.visa_brand,@ischar);
            this.ConstructionParser=p;
        end
    end
    
    methods (Access=public)
        function this=MyInstrument(interface, address, varargin)
            createConstructionParser(this);      
            %Loads parsed variables into class properties
            parseClassInputs(this,interface,address,varargin{:})
        end
        
        function delete(this)         
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            try
                delete(this.Device);
            catch
                warning('Device object cannot be deleted')
            end
        end    
        
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
        end
        
        % Read all the relevant instrument properties and return as a
        % file header structure.
        % Dummy method that needs to be re-defined by a parent class
        function HdrStruct=readHeader(this)
            HdrStruct.name.value = this.name;
            HdrStruct.name.str_spec = '%s';
            
            HdrStruct.interface.value = this.interface;
            HdrStruct.interface.str_spec = '%s';
            
            HdrStruct.address.value = this.address;
            HdrStruct.address.str_spec = '%s';
        end
       
        
        %% Connect, open, configure and close the device
        % Connects to the device
        function connectDevice(this, interface, address)
            try
                % visa brand, 'ni' by default
                vb = this.visa_brand;
                switch lower(interface)
                    case 'instr_list'
                        % load the InstrumentList structure
                        InstrumentList = getLocalSettings('InstrumentList');
                        % In this case 'address' is the instrument name in
                        % the list
                        instr_name = address;
                        if ~isfield(InstrumentList, instr_name)
                            error('%s is not a field of InstrumentList',...
                                instr_name)
                        end
                        % A check to prevent hypothetical endless recursion
                        if isequal(InstrumentList.(instr_name).interface,'instr_list')
                            error('')
                        end
                        % Connect using the loaded parameters 
                        connectDevice(this,...
                            InstrumentList.(instr_name).interface,...
                            InstrumentList.(instr_name).address);
                        % Assign name automatically, but not overwrite if
                        % already specified
                        if isempty(this.name)
                            this.name = instr_name;
                        end
                    case 'constructor'
                        % in this case the 'address' is a command 
                        % (ObjectConstructorName) as returned by the 
                        % instrhwinfo
                        this.Device=eval(address);
                    case 'visa'
                        this.Device=visa(vb, address);
                    case 'tcpip'
                        % Works only with default socket. Use 'visa' or
                        % 'constructor' if socket needs to be specified
                        this.Device=visa(vb, sprintf(...
                            'TCPIP0::%s::inst0::INSTR',address));
                    case 'usb'
                        this.Device=visa(vb, sprintf(...
                            'USB0::%s::INSTR',address));
                    case 'serial'
                        com_no = sscanf(address,'COM%i');
                        this.Device = visa(vb, sprintf(...
                            'ASRL%i::INSTR',com_no));
                    otherwise
                        warning('Device is not connected: unknown interface');
                end
                configureDeviceDefault(this);
            catch
                warning('Device is not connected');
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
        
        %Checks if the connection to the device is open
        function bool=isopen(this)
            try
                bool=strcmp(this.Device.Status, 'open');
            catch
                warning('Cannot access device Status property');
                bool=false;
            end
        end   
    end
end