% The class for communication with Agilent E5061B Network Analyzer
classdef MyNa < MyScpiInstrument
    
    properties(Access=public)
        Trace1
        Trace2
        
        transf_n=1; % trace that triggers NewData event
    end
    
    properties (SetAccess=protected, GetAccess=public)
        active_trace = -1; % manipulating with active traces seems unavoidable 
        % for selecting the data format. -1 stands for unknown
        
        % data formats for the traces 1-2, options:
        % 'PHAS', 'SLIN', 'SLOG', 'SCOM', 'SMIT', 'SADM', 'MLOG', 'MLIN', 
        %'PLIN', 'PLOG', 'POL'
        form1 = 'MLOG';
        form2 = 'PHAS';
    end

    methods
        function this=MyNa(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            this.Trace1 = MyTrace();
            this.Trace2 = MyTrace();
            this.Trace1.unit_x = 'Hz';
            this.Trace1.name_x = 'Frequency';
            this.Trace2.unit_x = 'Hz';
            this.Trace2.name_x = 'Frequency';
        end
        
        % Generate a new data event with header collection suppressed
        function transferTrace(this, n_trace)
            trace_tag = sprintf('Trace%i', n_trace);
            % Assign either Trace1 or 2 to Trace while keeping the metadata 
            this.(trace_tag).MeasHeaders=copy(this.Trace.MeasHeaders);
            this.Trace=copy(this.(trace_tag));
            
            triggerNewData(this,'new_header',false);
        end
        
        function data = readTrace(this, n_trace)
            writeActiveTrace(this, n_trace);
            freq_str = strsplit(query(this.Device,':SENS1:FREQ:DATA?'),',');
            data_str = strsplit(query(this.Device,':CALC1:DATA:FDAT?'),',');
            data = struct();
            data.x = str2double(freq_str);
            % In the returned string there is in general 2 values for each
            % frequency point. In the Smith data format this can be used to
            % transfer magnitude and phase of the signal in one trace. With
            % MLOG, MLIN and PHAS format settings every 2-nd element should
            % be 0
            data.y1 = str2double(data_str(1:2:end));
            data.y2 = str2double(data_str(2:2:end));
            
            % set the Trace properties
            trace_tag = sprintf('Trace%i', n_trace);
            this.(trace_tag).x = data.x;
            this.(trace_tag).y = data.y1;
            
            if this.transf_n==n_trace
                this.Trace=copy(this.(trace_tag));
                triggerNewData(this);
            end
        end
        
        function writeActiveTrace(this, n_trace)
            fprintf(this.Device, sprintf(':CALC1:PAR%i:SEL',n_trace));
            this.active_trace = n_trace;
        end
        
        function writeTraceFormat(this, n_trace, fmt)
            this.writeActiveTrace(n_trace);
            n_str = num2str(n_trace);
            this.(['form',n_str]) = fmt;
            fprintf(this.Device, sprintf(':CALC1:FORM %s', fmt));
        end
        
        function singleSweep(this)
            openDevice(this); 
            writeProperty(this,'cont_trig', true);
            % Set the triger source to remote control
            writeProperty(this,'trig_source', 'BUS');
            % Start a sweep cycle
            fprintf(this.Device,':TRIG:SING');
            % Wait for the sweep to finish (for the query to return 1)
            query(this.Device,'*OPC?');
            closeDevice(this);
        end
        
        function startContSweep(this)
            openDevice(this); 
            writeProperty(this,'cont_trig', true);
            % Set the triger source to be internal
            writeProperty(this,'trig_source', 'INT');
            closeDevice(this);
        end
        
        function abortSweep(this)
            openDevice(this);
            writeProperty(this, 'trig_source', 'BUS');
            fprintf(this.Device,':ABOR');
            closeDevice(this);
        end
    end
    
    %% Protected functions
    methods (Access=protected)
        % Command attributes are {class, attributtes} accepted by
        % validateattributes()
        function createCommandList(this)
            addCommand(this,...
                'cent_freq',':SENS1:FREQ:CENT', 'default',1.5e6,...
                'fmt_spec','%e',...
                'info','(Hz)');
            addCommand(this,...
                'start_freq',':SENS1:FREQ:START', 'default',1e6,...
                'fmt_spec','%e',...
                'info','(Hz)');
            addCommand(this,...
                'stop_freq',':SENS1:FREQ:STOP', 'default',2e6,...
                'fmt_spec','%e',...
                'info','(Hz)');
            addCommand(this,...
                'span',':SENS1:FREQ:SPAN', 'default',1e6,...
                'fmt_spec','%e',...
                'info','(Hz)');
            % IF bandwidth
            addCommand(this,...
                'ifbw',':SENS1:BAND', 'default',100,...
                'fmt_spec','%e',...
                'info','IF bandwidth (Hz)');
            % number of points in the sweep
            addCommand(this,...
                'point_no',':SENS1:SWE:POIN', 'default',1000,...
                'fmt_spec','%i');
            % number of averages
            addCommand(this,...
                'average_no',':SENS1:AVER:COUN', 'default',1,...
                'fmt_spec','%i');
            % number of traces
            addCommand(this,...
                'trace_no',':CALC1:PAR:COUN', 'default',1,...
                'fmt_spec','%i',...
                'info','Number of traces');
            % linear or log sweep
            addCommand(this,...
                'sweep_type',':SENS1:SWE:TYPE', 'default','LIN',...
                'fmt_spec','%s',...
                'info','Linear or log sweep');
            % switch the output signal on/off
            addCommand(this,...
                'enable_out',':OUTP', 'default',0,...
                'fmt_spec','%b',...
                'info','output signal on/off');
            % probe power [dB]
            addCommand(this,...
                'power',':SOUR:POW:LEV:IMM:AMPL', 'default',-10,...
                'fmt_spec','%e',...
                'info','Probe power (dB)');
            % windows arrangement on the display, e.g 'D1'
            addCommand(this,...
                'disp_type',':DISP:WIND1:SPL', 'default','D1',...
                'fmt_spec','%s',...
                'info','Window arrangement');
            % Continuous sweep triggering 
            addCommand(this,...
                'cont_trig',':INIT1:CONT', 'default', 0,...
                'fmt_spec','%b');
            addCommand(this,...
                'trig_source', ':TRIG:SOUR', 'default', 'BUS',...
                'fmt_spec','%s')
            
            % Parametric commands for traces, i can be extended to 4
            for i = 1:2
                % measurement parameters for the traces 1-2, e.g. 'S21'
                i_str = num2str(i);
                addCommand(this,...
                    ['meas_par',i_str],[':CALC1:PAR',i_str,':DEF'],...
                    'default','S21',...
                    'fmt_spec','%s',...
                    'info','Measurement parameter');
            end
        end
    end
end
