% Class for controlling Tektronix RSA5103 and RSA5106 spectrum analyzers 

classdef MyTekRsaFvt < MyScpiInstrument & MyDataSource & MyCommCont ...
        & MyGuiCont

    methods (Access = public)
        function this = MyTekRsaFvt(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            this.Trace.unit_x = 's';
            this.Trace.unit_y = 'Hz';
            this.Trace.name_y = 'Frequency';
            this.Trace.name_x = 'Time';

            % Create communication object
            connect(this);              
            
            % Set up the list of communication commands
            createCommandList(this);
        end
        
        function str = idn(this)
            str = idn@MyInstrument(this);
            
            % The instrument needs to be in DPX Spectrum mode
            res = queryString(this, ':DISPlay:WINDow:ACTive:MEASurement?');
            assert(contains(lower(res), {'dpsa', 'dpx'}), ...
                'The spectrum analyzer must be in DPX Spectrum mode.');
        end
    end

    methods (Access = protected)
        function createCommandList(this)            
            % Frequency vs time measurement frequency (Hz)
            addCommand(this, 'measuremnt_freq', ':MEAS:FREQ',...
                'format',   '%e', ...
                'info',     '(Hz)');
            
            % Frequency vs time measurement bandwidth (Hz)
            addCommand(this, 'measurement_BW', ':FVT:FREQ:SPAN',...
                'format',   '%e', ...
                'info',     '(Hz)');
            
            % Frequency vs time display x extent (s)
            addCommand(this, 'disp_x_length', ':ANAL:LENG',...
                'format',   '%e', ...
                'info',     '(s)');
            
            % Frequency vs time display x offset (s)
            addCommand(this, 'disp_x_start', ':ANAL:STAR',...
                'format',   '%e', ...
                'info',     '(s)');
            
            % Frequency vs time display offset (Hz)
            addCommand(this, 'disp_y_offset', ':DISP:FVT:Y:OFFS',...
                'format',   '%e', ...
                'info',     '(Hz)');
            
            % Frequency vs time display scale (extent) (Hz)
            addCommand(this, 'disp_y_scale', ':DISP:FVT:Y',...
                'format',   '%e', ...
                'info',     '(Hz)');
        end
    end


    methods (Access = public)        
        function readTrace(this, varargin)
            % Ensure that device parameters, especially those that will be
            % later used for the calculation of frequency axis, are up to
            % date
            sync(this);

            writeString(this, 'fetch:fvt?');
            data = binblockread(this.Comm, 'float');

            % Calculate the time axis
            this.Trace.x = linspace(this.disp_x_start, ...
                this.disp_x_start + this.disp_x_length, length(data));

            this.Trace.y = data;
            
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

        % Extend readSettings function
        function Mdt = readSettings(this)

            %Call parent class method and then append parameters
            Mdt = readSettings@MyScpiInstrument(this);

        end
    end

end
