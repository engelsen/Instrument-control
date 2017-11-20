classdef MyNa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        ifbw; % IF bandwidth
        start_freq;
        stop_freq;
        cent_freq;
        span;
        power; % probe power
        trace_no; % number of traces
        enable_out; % switch the output signal on/off
        average_no; 
        point_no; % number of points in the sweep
        sweep_type; % linear or log sweep
        disp_type; % windows arrangement at the display, e.g 'D1'
        active_trace = -1; % manipulating with active traces seems unavoidable 
        % for selecting the data format. -1 stands for unknown
        cont_trig;
        
        % measurement parameters for the traces 1-2, e.g. 'S21'
        meas_par1;
        meas_par2; 
        
        % data formats for the traces 1-2, options:
        % 'PHAS', 'SLIN', 'SLOG', 'SCOM', 'SMIT', 'SADM', 'MLOG', 'MLIN', 'PLIN', 'PLOG', 'POL'
        form1 = 'MLOG';
        form2 = 'PHAS';
        
        data1 = struct();
        data2 = struct();
    end

    methods
        function this=MyNa(name, interface, address, varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            createCommandList(this);
            createCommandParser(this);
            
            switch interface
                case 'TCPIP'
                    connectTCPIP(this);
            end
            
            %Tests if device is working.
            try
                openDevice(this);
                closeDevice(this);
            catch
                error(['Failed to open communications with device.',...
                    ' Check that the address and interface is correct.',...
                    ' Currently the address is %s and the interface is ',...
                    '%s.'],this.address,this.interface)
            end
        end
        
        % Command attributes are {class, attributtes} accepted by
        % validateattributes()
        function createCommandList(this)
            addCommand(this,...
                'cent_freq','SENS1:FREQ:CENT %d', 'default',1.5e6,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'start_freq','SENS1:FREQ:START %d', 'default',1e6,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'stop_freq','SENS1:FREQ:STOP %d', 'default',2e6,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'span','SENS1:FREQ:SPAN %d', 'default',1e6,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'ifbw','SENS1:BAND %d', 'default',100,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'point_no','SENS1:SWE:POIN %i', 'default',1000,...
                'attributes',{{'numeric'},{'integer'}},'write_flag',true);
            addCommand(this,...
                'average_no','SENS1:AVER:COUN %i', 'default',0,...
                'attributes',{{'numeric'},{'integer'}},'write_flag',true);
            addCommand(this,...
                'trace_no','CALC1:PAR:COUN %i', 'default',1,...
                'attributes',{{'numeric'},{'integer'}},'write_flag',true);
            addCommand(this,...
                'sweep_type','SENS1:SWE:TYPE %s', 'default','LIN',...
                'attributes',{{'string'}},'write_flag',true);
            addCommand(this,...
                'enable_out','OUTP %d', 'default',0,...
                'attributes',{{'logical'}},'write_flag',true);
            addCommand(this,...
                'power','SOUR:POW:LEV:IMM:AMPL %d', 'default',-10,...
                'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,...
                'disp_type','DISP:WIND1:SPL %s', 'default','D1',...
                'attributes',{{'string'}},'write_flag',true);
            addCommand(this,...
                'cont_trig',':INIT1:CONT %s', 'default','OFF',...
                'attributes',{{'string'}},'write_flag',true);
            
            % Parametric commands
            % Measurement parameters for traces, i can be extended to 4
            for i = 1:2
                i_str = num2str(i);
                addCommand(this,...
                    ['meas_par',i_str],['CALC1:PAR',i_str,':DEF %s'],...
                    'default','S21',...
                    'attributes',{{'string'}},'write_flag',true);
            end
        end
        
        % Execute all the write commands with default values
        function writeAllDefaults(this)            
            for i=1:this.command_no
                if this.CommandList.(this.command_names{i}).write_flag
                    write(this.Device, ...
                        sprintf(this.CommandList.(this.command_names{i}).command,...
                        this.CommandList.(this.command_names{i}).default));
                    this.(this.command_names{i})=...
                        this.CommandList.(this.command_names{i}).default;
                end
            end
        end
        
        % Execute all the read commands and update corresponding properties
        function readAll(this)
            result=readProperty(this, this.command_names{:});
            res_names=fieldnames(result);
            for i=1:length(res_names)
                this.(res_names{i})=result.(res_names{i});
            end
        end
        
        function writePropertyHedged(this, varargin)
            this.openDevice();
            try
                this.writeProperty(varargin{:});
            catch
                disp('Error while writing the properties:');
                disp(varargin);
            end
            this.readAll();
            closeDevice(this);
        end
        
        function result = readPropertyHedged(this, varargin)
            this.openDevice();
            try
                result = this.readProperty(varargin{:});
            catch
                disp('Error while reading the properties:');
                disp(varargin);
            end
            this.closeDevice();
        end
        
        function readTrace(this, nTrace)
            this.writeActiveTrace(nTrace);
            dtag = sprintf('data%i', nTrace);
            freq_str = strsplit(query(this.Device,'SENS1:FREQ:DATA?'),',');
            data_str = strsplit(query(this.Device,'CALC1:DATA:FDAT?'),',');
            this.(dtag).x = str2double(freq_str);
            this.(dtag).y = str2double(data_str(1:2:end));
            this.(dtag).y2 = str2double(data_str(2:2:end));
        end
        
        function writeActiveTrace(this, nTrace)
            fprintf(this.Device, sprintf('CALC1:PAR%i:SEL',nTrace));
            this.active_trace = nTrace;
        end
        
        function writeTraceFormat(this, nTrace, fmt)
            this.writeActiveTrace(nTrace);
            n_str = num2str(nTrace);
            this.(['form',n_str]) = fmt;
            fprintf(this.Device, sprintf('CALC1:FORM %s', fmt));
        end
        
        function singleSweep(this)
            this.openDevice(); 
            % Set the triger source to be remote control
            fprintf(this.Device,':TRIG:SOUR BUS');
            % Start a sweep cycle
            fprintf(this.Device,':TRIG:SING');
            % Wait for the sweep to end
            query(this.Device,'*OPC?');
            this.closeDevice();
        end
        
        function startContSweep(this)
            this.openDevice(); 
            this.writeProperty('cont_trig', 'ON');
            % Set the triger source to be remote control
            fprintf(this.Device,':TRIG:SOUR BUS');
            % Start a sweep cycle
            fprintf(this.Device,':TRIG');
            this.closeDevice();
        end
        
        function abortSweep(this)
            this.openDevice();
            fprintf(this.Device,':ABOR');
            this.closeDevice();
        end
        
        function connectTCPIP(this)
            buffer = 1000 * 1024;
            visa_brand = 'ni';
            visa_address_rsa = sprintf('TCPIP0::%s::inst0::INSTR',...
                this.address);
            this.Device=visa(visa_brand, visa_address_rsa,...
                'InputBufferSize', buffer,...
                'OutputBufferSize', buffer);
            set(this.Device,'InputBufferSize',1e6);
            set(this.Device,'Timeout',10);
        end
    end
end
