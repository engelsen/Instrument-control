classdef MyNewportUsbComm < MySingletone
    
    properties (GetAccess=public, SetAccess=private)
        isbusy = false; % is driver in use 
        QueryData
    end
    
    methods(Access=private)
        % Guard the constructor against external invocation.  We only want
        % to allow a single instance of this class.  See description in
        % Singleton superclass.
        function this = MyNewportUsbComm()
            this.QueryData=System.Text.StringBuilder(64);
            loadLib(this);
        end
    end
    
    methods(Access=public)
        
        % Load dll
        function loadLib(this)
            dll_path = which('UsbDllWrap.dll');
            if isempty(dll_path)
                error(['UsbDllWrap.dll is not found. This library ',...
                    'is a part of Newport USB driver and needs ',...
                    'to be present on Matlab path.'])
            end
            NetAsm=NET.addAssembly(dll_path);
            % Create an instance of Newport.USBComm.USB class
            Type=GetType(NetAsm.AssemblyHandle,'Newport.USBComm.USB');
            this.Asm = System.Activator.CreateInstance(Type);
        end
        
        function query(this, addr, cmd)
            stat = Query(this.Asm, addr, cmd, this.QueryData);
            if stat==0
                bool=true;
            end
        end
    end
   
    methods(Static)
        % Concrete implementation.  See Singleton superclass.
        function this = getInstance()
            persistent UniqueInstance

            if isempty(UniqueInstance)||(~isvalid(UniqueInstance))
                this = MyNewportUsbComm();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
end

