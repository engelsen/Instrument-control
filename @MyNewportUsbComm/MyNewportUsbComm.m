classdef MyNewportUsbComm < MySingleton
    
    properties (GetAccess = public, SetAccess = private)
        
        % Driver in use
        isbusy = false
    end
    
    properties (Access = public)
        
        % An instance of Newport.USBComm.USB class 
        Usb
    end
    
    methods (Access = private)
        
        % The constructor of a singleton class should only be invoked from
        % the instance method.
        function this = MyNewportUsbComm()
            disp(['Creating a new instance of ' class(this)])
            loadLib(this);
        end
    end
    
    methods (Access = public)
        
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
            assert(~this.isbusy, 'NewportUsbComm is already in use.')
            
            this.isbusy = true;
            
            % Send query using QueryData buffer. A new buffer needs to be
            % created every time to ensure the absence of interference 
            % between different queries.
            QueryData = System.Text.StringBuilder(64);
            
            stat = Query(this.Usb, addr, cmd, QueryData);
            
            if stat ~= 0
                warning(['Query to Newport usb driver was unsuccessful.'...
                    errorCodeToMessage(this, stat)]);
            end
            
            str = char(ToString(QueryData));
            
            this.isbusy = false;
        end
    end
    
    methods (Access = private)
        
        % Convert the code returned by read/write/query functions to
        % a message
        function str = errorCodeToMessage(~, stat)
            switch stat
                case 0
                    
                    % No error
                    str = ''; 
                case -2
                    str = 'Error: Device timeout';
                case 1
                    str = 'Error: Duplicate USB address';
                otherwise
                    str = sprintf('Error Code = %i', stat);
            end
        end
    end
   
    methods (Static)
        
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

