classdef MyNa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        ifbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        power;
        Trace;
    end
    methods
        function this=MyNa(name, interface, address, varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            createCommandList(this);
            createCommandParser(this);
            if this.enable_gui; initGui(this); end;
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
            addCommand(this,'span','SOUR:POW:LEV:IMM:AMPL %d',...
                'default',1,'attributes',{{'numeric'}},'power',true);

        end
    end
end
