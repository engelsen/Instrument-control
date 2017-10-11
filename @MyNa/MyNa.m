classdef MyNa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        ifbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        Trace;
    end
    methods
        function this=MyNa(name, interface, address, varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            createCommandList(this);
            createCommandParser(this);
            if this.enable_gui; initGui(this); end;
        end
        
       
        function readProperty(this, varargin)
            for i=1:length(varargin)
                if ~isprop(this, varargin{i})
                    error('%s is not a property of the class',varargin{i})
                end
                %Finds the index of the % sign which indicates where the value
                %to be written is supplied
                ind=strfind(this.CommandList.(varargin{i}).command,'%');
                %Creates the correct read command 
                read_command=[this.CommandList.(varargin{i}).command(1:(ind-2)),'?'];
                %Reads the property from the device and stores it in the
                %correct place
                this.(varargin{i})=str2double(this.read(read_command));
            end
        end
        
        function createCommandList(this)
            addCommand(this,'cent_freq','SENS:FREQ:CENT %d',...
                'default',1.5e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'start_freq','SENS:FREQ:START %d',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'stop_freq','SENS:FREQ:STOP %d',...
                'default',2e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'span','SENS:FREQ:SPAN %d',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
        end
    end
end
