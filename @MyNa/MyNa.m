% The class for communication with Agilent E5061B Network Analyzer
classdef MyNa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        active_trace = -1; % manipulating with active traces seems unavoidable 
        % for selecting the data format. -1 stands for unknown
        
        % data formats for the traces 1-2, options:
        % 'PHAS', 'SLIN', 'SLOG', 'SCOM', 'SMIT', 'SADM', 'MLOG', 'MLIN', 
        %'PLIN', 'PLOG', 'POL'
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
                'cent_freq','SENS1:FREQ:CENT', 'default',1.5e6,...
                'str_spec','d');
            addCommand(this,...
                'start_freq','SENS1:FREQ:START', 'default',1e6,...
                'str_spec','d');
            addCommand(this,...
                'stop_freq','SENS1:FREQ:STOP', 'default',2e6,...
                'str_spec','d');
            addCommand(this,...
                'span','SENS1:FREQ:SPAN', 'default',1e6,...
                'str_spec','d');
            % IF bandwidth
            addCommand(this,...
                'ifbw','SENS1:BAND', 'default',100,...
                'str_spec','d');
            % number of points in the sweep
            addCommand(this,...
                'point_no','SENS1:SWE:POIN', 'default',1000,...
                'str_spec','i');
            % number of averages
            addCommand(this,...
                'average_no','SENS1:AVER:COUN', 'default',1,...
                'str_spec','i');
            % number of traces
            addCommand(this,...
                'trace_no','CALC1:PAR:COUN', 'default',1,...
                'str_spec','i');
            % linear or log sweep
            addCommand(this,...
                'sweep_type','SENS1:SWE:TYPE', 'default','LIN',...
                'str_spec','s');
            % switch the output signal on/off
            addCommand(this,...
                'enable_out','OUTP', 'default',0,...
                'str_spec','b');
            % probe power [dB]
            addCommand(this,...
                'power','SOUR:POW:LEV:IMM:AMPL', 'default',-10,...
                'str_spec','d');
            % windows arrangement at the display, e.g 'D1'
            addCommand(this,...
                'disp_type','DISP:WIND1:SPL', 'default','D1',...
                'str_spec','s');
            % Continuous sweep triggering 'ON'/'OFF'
            addCommand(this,...
                'cont_trig',':INIT1:CONT', 'default','OFF',...
                'str_spec','s');
            
            % Parametric commands for traces, i can be extended to 4
            for i = 1:2
                % measurement parameters for the traces 1-2, e.g. 'S21'
                i_str = num2str(i);
                addCommand(this,...
                    ['meas_par',i_str],['CALC1:PAR',i_str,':DEF'],...
                    'default','S21',...
                    'str_spec','s');
            end
        end
        
        function readTrace(this, nTrace)
            this.writeActiveTrace(nTrace);
            dtag = sprintf('data%i', nTrace);
            freq_str = strsplit(query(this.Device,'SENS1:FREQ:DATA?'),',');
            data_str = strsplit(query(this.Device,'CALC1:DATA:FDAT?'),',');
            this.(dtag).x = str2double(freq_str);
            % In the returned string there is in general 2 values for each
            % frequency point. In the Smith data format this can be used to
            % transfer magnitude and phase of the signal in one trace. With
            % MLOG, MLIN and PHAS format settings every 2-nd element should
            % be 0
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
            % Wait for the sweep to finish (the command returns 1) when it
            % happens
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
