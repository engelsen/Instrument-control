classdef MyNewportUsbComm < MySingleton
    
    properties (GetAccess = public, SetAccess = private)
        isbusy = false  % driver in use 
        QueryData       % query buffer
    end
    
    properties (Access = public)
        Usb % Instance of Newport.USBComm.USB class 
    end
    
    methods(Access = private)
        
        % The constructor of a singleton class should only be invoked from
        % the instance method.
        function this = MyNewportUsbComm()
            this.QueryData = System.Text.StringBuilder(64);
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
            
            % Send query using the QueryData buffer
            stat = Query(this.Usb, addr, cmd, this.QueryData);
            if stat == 0
                str = char(ToString(this.QueryData));
            else
                str = '';
                warning('Query to Newport usb driver was unsuccessful.');
            end
            this.isbusy = false;
        end
    end
   
    methods(Static)
        
        % Concrete implementation of the singleton constructor.
        function this = instance()
            persistent UniqueInstance

            if isempty(UniqueInstance) || ~isvalid(UniqueInstance)
                disp('Creating a new instance of NewportUsbComm')
                this = MyNewportUsbComm();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
end

