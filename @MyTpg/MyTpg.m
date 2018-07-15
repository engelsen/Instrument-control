% Class for communication with Pfeiffer TPG single and dual pressure gauge
% controllers. 
% Tested with TPG 361 and TPG 362.
classdef MyTpg < MyInstrument
    
    properties (Constant=true)
        % Named constants for communication
        ETX = char(3); % end of text
        CR = char(13); % carriage return
        LF = char(10); %#ok<CHARTEN> % line feed
        ENQ = char(5); % enquiry
        ACK = char(6); % acknowledge
        NAK = char(21); % negative acknowledge
    end
    
    properties (SetAccess=protected, GetAccess=public)
        pressure1 = 0; % numeric values of pressure
        pressure2 = 0;
        stat1;
        stat2;
        gauge_id1;
        gauge_id2;
        pressure_unit = '';
    end
    
    properties (Dependent=true)
        pressure_str1; % display string with measurement unit
        pressure_str2;
    end
    
    methods (Access=public)
        function this = MyTpg(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            connectDevice(this, interface, address);
        end
        
        % read pressure from a single channel or both channels at a time
        function p_arr = readPressure(this)
            query(this.Device,['PRX',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);        
            % Extract pressure and gauge status from reading.
            arr = sscanf(str,'%i,%e,%i,%e');
            p_arr=arr(2:2:end);
            this.pressure1 = p_arr(1);
            this.pressure2 = p_arr(2);
            % Status codes:
            % 0 –> Measurement data okay
            % 1 –> Underrange
            % 2 –> Overrange
            % 3 –> Sensor error
            % 4 –> Sensor off (IKR, PKR, IMR, PBR)
            % 5 –> No sensor (output: 5,2.0000E-2 [hPa])
            % 6 –> Identification error  
            this.stat1 = gaugeStatusFromCode(this, arr(1));
            this.stat2 = gaugeStatusFromCode(this, arr(3));
            triggerNewData(this);
        end
        
        function pu = readPressureUnit(this)
            query(this.Device,['UNI',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            % Pressure units correspondence table:
            % 0 –> mbar/bar
            % 1 –> Torr
            % 2 –> Pascal
            % 3 –> Micron
            % 4 –> hPascal (default)
            % 5 –> Volt
            pu_code = sscanf(str,'%i');
            pu = pressureUnitFromCode(this, pu_code);
            this.pressure_unit = pu;
        end
        
        function id_list = readGaugeId(this)
            query(this.Device,['TID',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            id_list = deblank(strsplit(str,{','}));
            this.gauge_id1 = id_list{1};
            this.gauge_id2 = id_list{2};
        end
        
        function p_arr = readAllHedged(this)
            openDevice(this);
            try
                p_arr = readPressure(this);
                readPressureUnit(this);
                readGaugeId(this);
            catch
                p_arr = [0,0];
                warning('Error while communicating with gauge controller')
            end
            closeDevice(this)
        end
        
        function code_list = turnGauge(this)
            query(this.Device,['SEN',char(1,1),this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            code_list = deblank(strsplit(str,{','}));
        end
        
        % Convert numerical code for gauge status to a string
        function str = gaugeStatusFromCode(~, code)
            switch int8(code)
                case 0
                    str = 'Measurement data ok';
                case 1
                    str = 'Underrange';
                case 2
                    str = 'Overrange';
                case 3
                    str = 'Sensor error';
                case 4
                    str = 'Sensor off';
                case 5
                    str = 'No sensor';
                case 6
                    str = 'Identification error';
                otherwise
                    str = '';
                    warning('Unknown gauge status code %i', code);
            end
        end
        
        % Convert numerical code for pressure unit to a string
        function str = pressureUnitFromCode(~, code)
            switch int8(code)
                case 0
                    str = 'mbar';
                case 1
                    str = 'Torr';
                case 2
                    str = 'Pa';
                case 3
                    str = 'Micron';
                case 4
                    str = 'hPa';
                case 5
                    str = 'Volt';
                otherwise
                    str = '';
                    warning('unknown pressure unit, code=%i',pu_num)
            end
        end
    end
    
    %% Get functions
    methods
        function p_str = get.pressure_str1(this)
            p_str = sprintf('%.2e %s', this.pressure1, this.pressure_unit);
        end
        
        function p_str = get.pressure_str2(this)
            p_str = sprintf('%.2e %s', this.pressure2, this.pressure_unit);
        end
    end
end

