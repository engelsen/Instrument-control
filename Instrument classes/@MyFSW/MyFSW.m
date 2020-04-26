% Class for controlling Tektronix RSA5103 and RSA5106 spectrum analyzers 

classdef MyFSW < MyScpiInstrument & MyDataSource & MyCommCont ...
        & MyGuiCont

    properties (SetAccess = protected, GetAccess = public)
        acq_trace  % The number of last read trace
    end

    methods (Access = public)
        function this = MyFSW(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            this.Trace.unit_x = 'Hz';
            this.Trace.unit_y = '$\mathrm{V}^2/\mathrm{Hz}$';
            this.Trace.name_y = 'Power';
            this.Trace.name_x = 'Frequency';

            % Create communication object
            connect(this);              
            
            % Set up the list of communication commands
            createCommandList(this);
        end
        %%%% delete later, I don't think DPX mode is available in FSW %%%%
        % function str = idn(this)
        %     str = idn@MyInstrument(this);
            
        %     % The instrument needs to be in DPX Spectrum mode
        %     res = queryString(this, ':DISPlay:WINDow:ACTive:MEASurement?');
        %     assert(contains(lower(res), {'dpsa', 'dpx'}), ...
        %         'The spectrum analyzer must be in DPX Spectrum mode.');
        % end
    end

    methods (Access = protected)
        function createCommandList(this)

            % We define commands for both the nominal and actual resolution
            % bandwidths as these two are useful in different
            % circumstances. The nominal one unlike the actual one takes
            % effect immediately after it is set to a new value, whereas
            % the actual one is the true rbw if the device does not follow
            % the nominal one (usually if the nominal rbw is is too small).
            addCommand(this, 'rbw', 'SENSe:BANDwidth:RESolution', ...
                'format',   '%e', ...
                'info',     'Nominal resolution bandwidth (Hz)');

            %%%% did not find how to get actual bandwidth from FSW %%%%
            % addCommand(this, 'rbw_act', ':DPX:BANDwidth:ACTual', ...
            %     'format',   '%e', ...
            %     'access',   'r', ...
            %     'info',     'Actual resolution bandwidth (Hz)');

            addCommand(this, 'bw_ratio', 'SENSe:BANDwidth:RESolution:RATio', ...
                'format',   '%e', ...
                'info',     'ratio between resolution bandwidth and the span');

            addCommand(this, 'auto_rbw', 'SENSe:BANDwidth:RESolution:AUTO', ...
                'format',   '%b');

            addCommand(this, 'span', 'SENSe:FREQuency:SPAN', ...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this,  'start_freq', 'SENSe:FREQuency:STARt',...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this, 'stop_freq', 'SENSe:FREQuency:STOP',...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this, 'cent_freq', 'SENSe:FREQuency:CENTer',...
                'format',   '%e', ...
                'info',     '(Hz)');

            % Continuous triggering
            addCommand(this, 'init_cont', 'INIT:CONT', ...
                'format',   '%b',...
                'info',     'Continuous triggering on/off');

            % Number of points in trace
            addCommand(this, 'point_no', 'SENSe:SWEep:POINts', ...
                'format',  '%i');


            % Reference level (dB)
            addCommand(this, 'ref_level','DISP:TRAC:Y:RLEV', ...
                'format',   '%e',...
                'info',     '(dB)');

            % Display scale per division (dBm/div)
            addCommand(this, 'disp_y_scale', 'DISP:TRAC:Y',...
                'format',   '%e', ...
                'info',     '(dB)');

            % Display vertical offset (dBm)
            addCommand(this, 'disp_y_offset', 'DISP:TRAC:Y:RLEV:OFFS', ...
                'format',   '%e', ...
                'info',     '(dBm)');

            % Parametric commands
            for i = 1:3
                i_str = num2str(i);

                % Display trace
                addCommand(this, ['disp_trace',i_str], ...
                    ['DISP:TRAC',i_str], ...
                    'format',   '%b', ...
                    'info',     'on/off');

                % Trace Detection
                addCommand(this, ['det_trace',i_str],...
                    ['DET',i_str],...
                    'format',       '%s', ...
                    'value_list',   {'APE','AVER', 'NEG', 'POS'});

                % Trace Function
                addCommand(this, ['func_trace',i_str], ...
                    ['DISP:TRAC',i_str,':MODE'], ...
                    'format',       '%s', ...
                    'value_list',   {'AVER', 'VIEW', 'WRIT'});

                % Number of averages
                addCommand(this, ['average_no',i_str], ...
                    ['AVER:COUN'], ...
                    'format',   '%i');

                %%%% FSW43 does not have this feature. It could only count
                %%%% for a given number of traces
                %% Count completed averages
                %addCommand(this, ['cnt_trace',i_str], ...
                %    ['SENS:AVER:STAT',i_str], ...
                %    'format',   '%b', ...
                %    'info',     'Count completed averages');
            end
        end
    end


    methods (Access = public)        
        function readTrace(this, varargin)
            if ~isempty(varargin)
                n_trace = varargin{1};
            else
                n_trace = this.acq_trace;
            end

            % Ensure that device parameters, especially those that will be
            % later used for the calculation of frequency axis, are up to
            % date
            sync(this);
            writeString(this,'FORM:DATA REAL,32');
            writeString(this, sprintf('TRAC:DATA? TRACE%i', n_trace));
            data = binblockread(this.Comm, 'float');

            % Calculate the frequency axis
            this.Trace.x = linspace(this.start_freq, this.stop_freq,...
                this.point_no);

            % Calculates the power spectrum from the data, which is in dBm.
            % Output is in V^2/Hz
            this.Trace.y = (10.^(data/10))/this.rbw*50*0.001;

            this.acq_trace = n_trace;

            % Trigger acquired data event
            triggerNewData(this);
        end

        % Abort data acquisition
        function abortAcq(this)
            writeString(this, 'ABORt');
        end

        % Initiate data acquisition
        function initAcq(this)
            writeString(this, 'INIT');
        end

        % Wait for the current operation to be completed
        function val = opc(this)
            val = queryString(this, '*OPC?');
        end

        % Extend readSettings function
        function Mdt = readSettings(this)

            %Call parent class method and then append parameters
            Mdt = readSettings@MyScpiInstrument(this);

            %Hdr should contain single field
            addParam(Mdt, 'acq_trace', this.acq_trace, ...
                'comment', 'The number of last read trace');
        end

        function sync(this)
            cns = this.command_names;
            ind_r = structfun(@(x) ~isempty(x.read_command), ...
                this.CommandList);
            
            read_cns = cns(ind_r); % List of names of readable commands
            
            read_commands = cellfun(...
                @(x) this.CommandList.(x).read_command, read_cns,...
                'UniformOutput', false);
            res_list={};
            for i=1:length(read_cns)
                res_list{end+1,1} = queryStrings(this, read_commands{i});
            end
            res_list=rot90([res_list{:}],-1);
            if length(read_cns) == length(res_list)
                
                % Assign outputs to the class properties
                for i = 1:length(read_cns)
                    tag = read_cns{i};
                    
                    val = sscanf(res_list{i}, ...
                            this.CommandList.(tag).format);
                    
                    if ~isequal(this.CommandList.(tag).last_value, val)
                        
                        % Assign value without writing to the instrument
                        this.CommandWriteEnabled.(tag) = false;
                        this.(tag) = val;
                        this.CommandWriteEnabled.(tag) = true;
                    end
                end
            else
                warning(['Could not read %i out of %i parameters, ',...
                    'no properties of %s object are updated.'], ...
                    length(read_commands)-length(res_list), ...
                    length(read_commands), class(this));
            end
        end
    end

    methods
        function set.acq_trace(this, val)
            assert((val==1 || val==2 || val==3), ...
                'Acquisition trace number must be 1, 2 or 3.');
            this.acq_trace = val;
        end
    end
end
