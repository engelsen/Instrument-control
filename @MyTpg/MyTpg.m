% Class for communication with Pfeiffer TPG single and dual pressure gauge
% controllers. 
% Tested with TPG 361 and TPG 362.
classdef MyTpg < MyInstrument
    
    properties (Constant=true)
        % Named constants for communication
        ETX = 3; % end of text
        CR = 13; % carriage return
        LF = 10; % line feed
        ENQ = 5; % enquiry
        ACK = 6; % acknowledge
        NAK = 21; % negative acknowledge
    end
    
    properties (SetAccess=protected, GetAccess=public)
        pressure1;
        pressure2;
        stat1;
        stat2;
%         gauge_on1;
%         gauge_on2;
        gauge_id1;
        gauge_id2;
        pressure_unit;
    end
    
    methods (Access=public)
        function this = MyTpg(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            connectDevice(this, interface, address);
        end
        
        % read pressure from a single channel or both channels at a time
        function [st_code1, p1, st_code2, p2] = readPressure(this)
            fopen(this.Device);
            query(this.Device,['PRX',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            fclose(this.Device);           
            % Extract pressure and gauge status from reading.
            % Status codes:
            % 0 –> Measurement data okay
            % 1 –> Underrange
            % 2 –> Overrange
            % 3 –> Sensor error
            % 4 –> Sensor off (IKR, PKR, IMR, PBR)
            % 5 –> No sensor (output: 5,2.0000E-2 [hPa])
            % 6 –> Identification error  
            [st_code1, p1, st_code2, p2] = sscanf(str,'%i,%e,%i,%e');
            this.pressure1 = p1;
            this.pressure2 = p2;
            this.stat1 = gaugeStatusFromCode(this, st_code1);
            this.stat2 = gaugeStatusFromCode(this, st_code2);
            triggerNewData(this);
        end
        
        function pu = readPressureUnit(this)
            fopen(this.Device);
            query(this.Device,['UNI',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            fclose(this.Device);
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
        
        function readGaugeId(this)
            fopen(this.Device);
            query(this.Device,['TID',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            fclose(this.Device);
            id_list = strsplit(str,{',',' '});
            this.gauge_id1 = id_list{1};
            this.gauge_id2 = id_list{2};
        end
        
        % Convert numerical code for gauge status to a string
        function str = gaugeStatusFromCode(~, code)
            switch code
                case 0
                    str = 'Measurement data okay';
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
            switch code
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
end

