% The class for communication with Agilent E5061B Network Analyzer

classdef MyAgilentNa < MyScpiInstrument & MyCommCont & MyDataSource ...
        & MyGuiCont
    
    properties(Access = public, SetObservable)
        Trace1
        Trace2
        
        transf_n = 1 % trace that triggers NewData event
    end
    
    properties (SetAccess = protected, GetAccess = public, SetObservable)
        
        % Manipulating active traces seems unavoidable for data format
        % selection. -1 stands for unknown.
        active_trace = -1 
        
        % data formats for the traces 1-2, options:
        % 'PHAS', 'SLIN', 'SLOG', 'SCOM', 'SMIT', 'SADM', 'MLOG', 'MLIN', 
        %'PLIN', 'PLOG', 'POL'
        form1 = 'MLOG'
        form2 = 'PHAS'
    end

    methods
        function this = MyAgilentNa(varargin)
            P = MyClassParser(this);
            addParameter(P, 'enable_gui', false);
            processInputs(P, this, varargin{:});
            
            this.Trace1 = MyTrace();
            this.Trace2 = MyTrace();
            this.Trace1.unit_x = 'Hz';
            this.Trace1.name_x = 'Frequency';
            this.Trace2.unit_x = 'Hz';
            this.Trace2.name_x = 'Frequency';
            
            connect(this);
            createCommandList(this);
            
            if P.Results.enable_gui
                createGui(this);
            end
        end
        
        % Generate a new data event with header collection suppressed
        function transferTrace(this, n_trace)
            trace_tag = sprintf('Trace%i', n_trace);
            
            % Assign either Trace1 or 2 to Trace while keeping the metadata 
            this.(trace_tag).UserMetadata = copy(this.Trace.UserMetadata);
            this.Trace = copy(this.(trace_tag));
            
            triggerNewData(this, 'new_header', false);
        end
        
        function readTrace(this, n_trace)
            writeActiveTrace(this, n_trace);
            
            freq_str = strsplit(queryString(this,':SENS1:FREQ:DATA?'),',');
            data_str = strsplit(queryString(this,':CALC1:DATA:FDAT?'),',');
            
            data_x = str2double(freq_str);
            
            % In the returned string there is in general 2 values for each
            % frequency point. In the Smith data format this can be used to
            % transfer magnitude and phase of the signal in one trace. With
            % MLOG, MLIN and PHAS format settings every 2-nd element should
            % be 0
            data_y1 = str2double(data_str(1:2:end));
            
            % set the Trace properties
            trace_tag = sprintf('Trace%i', n_trace);
            this.(trace_tag).x = data_x;
            this.(trace_tag).y = data_y1;
            
            if this.transf_n == n_trace
                this.Trace = copy(this.(trace_tag));
                triggerNewData(this);
            end
        end
        
        function writeActiveTrace(this, n_trace)
            writeString(this, sprintf(':CALC1:PAR%i:SEL', n_trace));
            this.active_trace = n_trace;
        end
        
        function writeTraceFormat(this, n_trace, fmt)
            writeActiveTrace(this, n_trace);
            
            n_str = num2str(n_trace);
            
            this.(['form', n_str]) = fmt;
            writeString(this, sprintf(':CALC1:FORM %s', fmt));
        end
        
        function singleSweep(this)
            
            % Set the triger source to remote control
            this.trig_source = 'BUS';
            this.cont_trig = true;
            
            % Start a sweep cycle
            writeString(this, ':TRIG:SING');
            
            % Wait for the sweep to finish (for the query to return 1)
            queryString(this, '*OPC?');
        end
        
        function startContSweep(this)
            
            % Set the triger source to internal
            this.trig_source = 'INT';
            this.cont_trig = true;
        end
        
        function abortSweep(this)
            this.trig_source = 'BUS';
            writeString(this, ':ABOR');
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            addCommand(this, 'cent_freq', ':SENS1:FREQ:CENT', ...
                'format',   '%e', ...
                'info',     '(Hz)');
            
            addCommand(this, 'start_freq', ':SENS1:FREQ:START', ...
                'format',   '%e',...
                'info',     '(Hz)');
            
            addCommand(this, 'stop_freq', ':SENS1:FREQ:STOP', ...
                'format',   '%e',...
                'info',     '(Hz)');
            
            addCommand(this, 'span', ':SENS1:FREQ:SPAN', ...
                'format',   '%e',...
                'info',     '(Hz)');
            
            addCommand(this, 'ifbw', ':SENS1:BAND', ...
                'format',   '%e', ...
                'info',     'IF bandwidth (Hz)');
            
            addCommand(this, 'point_no', ':SENS1:SWE:POIN', ...
                'format',   '%i');

            addCommand(this, 'average_no', ':SENS1:AVER:COUN', ...
                'format',   '%i');

            addCommand(this, 'trace_no', ':CALC1:PAR:COUN', ...
                'format',       '%i',...
                'info',         'Number of traces', ...
                'value_list',   {1, 2});

            addCommand(this, 'sweep_type', ':SENS1:SWE:TYPE', ...
                'format',       '%s',...
                'info',         'Linear or log sweep', ...
                'value_list',   {'LIN', 'LOG'});

            addCommand(this, 'enable_out', ':OUTP', ...
                'format',   '%b',...
                'info',     'output signal on/off');

            addCommand(this, 'power', ':SOUR:POW:LEV:IMM:AMPL', ...
                'format',   '%e',...
                'info',     'Probe power (dB)');

            addCommand(this, 'disp_type', ':DISP:WIND1:SPL',...
                'format',   '%s',...
                'info',     'Window arrangement', ...
                'default',  'D1');

            addCommand(this, 'cont_trig', ':INIT1:CONT', ...
                'format',   '%b');
            
            addCommand(this, 'trig_source', ':TRIG:SOUR', ...
                'format',   '%s', ...
                'default', 'BUS')
            
            % Parametric commands for traces, i can be extended to 4
            for i = 1:2
                
                % measurement parameters for the traces 1-2, e.g. 'S21'
                i_str = num2str(i);
                addCommand(this,...
                    ['meas_par',i_str], [':CALC1:PAR',i_str,':DEF'], ...
                    'format',   '%s',...
                    'info',     'Measurement parameter', ...
                    'default',  'S21');
            end
        end
    end
end
