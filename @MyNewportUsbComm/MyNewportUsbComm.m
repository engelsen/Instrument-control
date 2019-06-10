classdef MyNewportUsbComm < MySingleton
    
    properties (GetAccess = public, SetAccess = private)
        
        % Driver in use
        isbusy = false
        
        % QueryData objects are stored in order to ensure that these 
        % objects are not deleted before the Newport driver finishes 
        % operations on them
        QueryRecord = {}
    end
    
    properties (Access = public)
        
        % An instance of Newport.USBComm.USB class 
        Usb
    end
    
    properties (Access = private)
        query_record_max_length = 1e4
    end
    
    methods(Access = private)
        
        % The constructor of a singleton class should only be invoked from
        % the instance method.
        function this = MyNewportUsbComm()
            disp(['Creating a new instance of ' class(this)])
            loadLib(this);
        end
    end
    
    methods(Access = public)
        
        % Load dll
        function loadLib(this)
            dll_path = which('UsbDllWrap.dll');
            if isempty(dll_path)
                error(['UsbDllWrap.dll is not found. This library ',...
                    'is a part of Newport USB driver and needs ',...
                    'to be present on Matlab path.'])
            end
            NetAsm = NET.addAssembly(dll_path);
            
            % Create an instance of Newport.USBComm.USB class
            Type = GetType(NetAsm.AssemblyHandle,'Newport.USBComm.USB');
            this.Usb = System.Activator.CreateInstance(Type);
        end
        
        function str = query(this, addr, cmd)
            
            % Check if the driver is already being used by another process.
            % A race condition with various strange consequences is 
            % potentially possible if it is.
            if this.isbusy
                warning('NewportUsbComm is already in use')
            end
            
            this.isbusy = true;
            
            % Send query using QueryData buffer. A new buffer needs to be
            % created every time to ensure the absence of interference 
            % between different queries.
            QueryData = System.Text.StringBuilder(64);
            
            stat = Query(this.Usb, addr, cmd, QueryData);
            
            if stat == 0
                str = char(ToString(QueryData));
            else
                str = '';
                warning('Query to Newport usb driver was unsuccessful.');
            end
            
            this.QueryRecord = [this.QueryRecord, {QueryData}];
            ml = this.query_record_max_length;
            if length(this.QueryRecord) > ml
                this.QueryRecord = this.QueryRecord(end-ml+1:end);
            end
            
            this.isbusy = false;
        end
    end
   
    methods(Static)
        
        % Concrete implementation of the singleton constructor.
        function this = instance()
            persistent UniqueInstance

            if isempty(UniqueInstance) || ~isvalid(UniqueInstance)
                this = MyNewportUsbComm();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
end

