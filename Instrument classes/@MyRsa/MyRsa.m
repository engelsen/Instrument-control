% Class for controlling Tektronix RSA5103 and RSA5106 spectrum analyzers 

classdef MyRsa < MyScpiInstrument & MyDataSource & MyCommCont

    properties (SetAccess = protected, GetAccess = public)
        acq_trace = [] % The number of last read trace
    end

    methods (Access = public)
        function this = MyRsa(varargin)
            this@MyCommCont(varargin{:});

            this.Trace.unit_x = 'Hz';
            this.Trace.unit_y = '$\mathrm{V}^2/\mathrm{Hz}$';
            this.Trace.name_y = 'Power';
            this.Trace.name_x = 'Frequency';

            createCommandList(this);
        end
    end


    methods (Access = protected)

        function createCommandList(this)

            % We define commands for both the nominal and actual resolution
            % bandwidths as these two are useful in different
            % circumstances. The nominal one unlike the actual one takes
            % effect immediately after it is set to a new value, whereas
            % the actual one is the true rbw if the device does not follow
            % the nominal one (usually if the nominal rbw is is too small).
            addCommand(this, 'rbw', ':DPX:BANDwidth:RESolution', ...
                'format',   '%e', ...
                'info',     'Nominal resolution bandwidth (Hz)');

            addCommand(this, 'rbw_act', ':DPX:BANDwidth:ACTual', ...
                'format',   '%e', ...
                'access',   'r', ...
                'info',     'Actual resolution bandwidth (Hz)');

            addCommand(this, 'auto_rbw', ':DPX:BAND:RES:AUTO', ...
                'format',   '%b');

            addCommand(this, 'span', ':DPX:FREQ:SPAN', ...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this,  'start_freq', ':DPX:FREQ:STAR',...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this, 'stop_freq', ':DPX:FREQ:STOP',...
                'format',   '%e', ...
                'info',     '(Hz)');

            addCommand(this, 'cent_freq', ':DPX:FREQ:CENT',...
                'format',   '%e', ...
                'info',     '(Hz)');

            % Continuous triggering
            addCommand(this, 'init_cont', ':INIT:CONT', ...
                'format',   '%b',...
                'info',     'Continuous triggering on/off');

            % Number of points in trace
            addCommand(this, 'point_no', ':DPSA:POIN:COUN', ...
                'format',       'P%i', ...
                'value_list',   {801, 2401, 4001, 10401});

            % Reference level (dB)
            addCommand(this, 'ref_level',':INPut:RLEVel', ...
                'format',   '%e',...
                'info',     '(dB)');

            % Display scale per division (dBm/div)
            addCommand(this, 'disp_y_scale', ':DISPlay:DPX:Y:PDIVision',...
                'format',   '%e', ...
                'info',     '(dBm/div)');

            % Display vertical offset (dBm)
            addCommand(this, 'disp_y_offset', ':DISPLAY:DPX:Y:OFFSET', ...
                'format',   '%e', ...
                'info',     '(dBm)');

            % Parametric commands
            for i = 1:3
                i_str = num2str(i);

                % Display trace
                addCommand(this, ['disp_trace',i_str], ...
                    [':TRAC',i_str,':DPX'], ...
                    'format',   '%b', ...
                    'info',     'on/off');

                % Trace Detection
                addCommand(this, ['det_trace',i_str],...
                    [':TRAC',i_str,':DPX:DETection'],...
                    'format',       '%s', ...
                    'value_list',   {'AVERage', 'NEGative', 'POSitive'});

                % Trace Function
                addCommand(this, ['func_trace',i_str], ...
                    [':TRAC',i_str,':DPX:FUNCtion'], ...
                    'format',       '%s', ...
                    'value_list',   {'AVERage', 'HOLD', 'NORMal'});

                % Number of averages
                addCommand(this, ['average_no',i_str], ...
                    [':TRAC',i_str,':DPX:AVER:COUN'], ...
                    'format',   '%i');

                % Count completed averages
                addCommand(this, ['cnt_trace',i_str], ...
                    [':TRACe',i_str,':DPX:COUNt:ENABle'], ...
                    'format',   '%b', ...
                    'info',     'Count completed averages');
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

            writeString(this, sprintf('fetch:dpsa:res:trace%i?', n_trace));
            data = binblockread(this.Comm, 'float');

            % Calculate the frequency axis
            this.Trace.x = linspace(this.start_freq, this.stop_freq,...
                this.point_no);

            % Calculates the power spectrum from the data, which is in dBm.
            % Output is in V^2/Hz
            this.Trace.y = (10.^(data/10))/this.rbw_act*50*0.001;

            this.acq_trace = n_trace;

            % Trigger acquired data event
            triggerNewData(this);
        end

        % Abort data acquisition
        function abortAcq(this)
            writeString(this, ':ABORt');
        end

        % Initiate data acquisition
        function initAcq(this)
            writeString(this, ':INIT');
        end

        % Wait for the current operation to be completed
        function val = opc(this)
            val = queryString(this, '*OPC?');
        end

        % Extend readHeader function
        function Hdr = readHeader(this)

            %Call parent class method and then append parameters
            Hdr = readHeader@MyScpiInstrument(this);

            %Hdr should contain single field
            addParam(Hdr, Hdr.field_names{1}, ...
                'acq_trace', this.acq_trace, ...
                'comment', 'The number of last read trace');
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
