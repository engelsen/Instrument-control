% Class for communication with Pfeiffer TPG single and dual pressure gauge
% controllers. Tested with TPG 361 and TPG 362.
classdef MyTpg < dynamicprops
    
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
        name='';
        interface='';
        address='';
        %Contains the device object. struct() is a dummy, as Device 
        %needs to always support properties for consistency.
        Device=struct();
        %Trace object for storing data
        Trace=MyTrace();
        
        pressure1;
        pressure2;
        stat1;
        stat2;
        gauge_on1;
        gauge_on2;
        gauge_id1;
        gauge_id2;
        pressure_unit;
    end
    
    methods (Access=public)
        function this = MyTpg(interface, address, varargin)
            % use parser to check validity of inputs and add optional
            % arguments
            p=inputParser();
            % do not throw error if some parameters are unmatched
            p.KeepUnmatched = true; 
            addRequired(p,'interface',@ischar);
            addRequired(p,'address',@ischar);
            addParameter(p,'name','',@ischar);
           
            parse(p,interface,address,varargin{:});      
            %Loads parsed variables into class properties
            this.name=p.Results.name;
            this.interface=p.Results.interface;
            this.address=p.Results.address;
        end
        
        % read pressure from a single channel or both channels at a time
        function prs = readPressure(this, channel)
            fopen(this.Device);
            str = query(this.Device,['PRX',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            % Extract pressure and gauge status from reading.
            % Status codes:
            % 0 –> Measurement data okay
            % 1 –> Underrange
            % 2 –> Overrange
            % 3 –> Sensor error
            % 4 –> Sensor off (IKR, PKR, IMR, PBR)
            % 5 –> No sensor (output: 5,2.0000E-2 [hPa])
            % 6 –> Identification error  
            [stat1, p1, stat2, p2] = sscanf(str,'%i,%e,%i,%e');
            fclose(this.Device);
        end
        
        function pu = readPressureUnit(this)
            fopen(this.Device);
            str = query(this.Device,['UNI',this.CR,this.LF]);
            str = query(this.Device,this.ENQ);
            % Pressure unit:
            % 0 –> mbar/bar
            % 1 –> Torr
            % 2 –> Pascal
            % 3 –> Micron
            % 4 –> hPascal (default)
            % 5 –> Volt
            pu_num = sscanf(str,'%i');
            switch pu_num
                case 0
                    pu = 'mbar';
                case 1
                    pu = 'Torr';
                case 2
                    pu = 'Pa';
                case 3
                    pu = 'Micron';
                case 4
                    pu = 'hPa';
                case 5
                    pu = 'Volt';
                otherwise
                    pu = '';
                    warning('unknown pressure unit, code=%i',pu_num)
            end
            fclose(this.Device);
        end
    end
end

