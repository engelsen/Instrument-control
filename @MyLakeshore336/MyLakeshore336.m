% Class communication with Lakeshore Model 336 temperature controller. 
classdef MyLakeshore336 < MyInstrument
    
    properties (Access=public)
        temp_unit = 'K'; % temperature unit, K or C
    end
    
    properties (SetAccess=protected, GetAccess=public)
        temp = {[],[],[],[]}; % cell array of temperatures
        setpoint = {[],[],[],[]};
        inp_sens_names = {'','','',''}; % input sensor names
        heater_rng = {[],[],[],[]}; % cell array of heater range codes
    end
    
    properties (Dependent=true)
        heater_rng_str % heater range
        temp_str % temperatures with measurement unit
    end
    
    methods (Access=public)
        function this=MyLakeshore336(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            connectDevice(this, interface, address);
        end
        
        % read 
        function temp_arr = readAllHedged(this)
            openDevice(this);
            temp_arr = readTemperature(this);
            readHeaterRange(this, 'all');
            readSetpoint(this, 'all');
            readInputSensorName(this);
            closeDevice(this);
        end
        
        function temp_arr = readTemperature(this)
            % unit = C or K;
            tu = this.temp_unit;
            cmd_str = [tu,'RDG? A;',tu,'RDG? B;',tu,'RDG? C;',tu,'RDG? D'];
            resp_str = query(this.Device, cmd_str);
            resp_split = strsplit(resp_str,';','CollapseDelimiters',false);
            % convert to numbers
            this.temp = cellfun(@str2num,resp_split,'UniformOutput',false);
            % create an output array replacing missing readings with NaN
            temp_arr = [NaN, NaN, NaN, NaN];
            for i=1:4
                if ~isempty(this.temp{i})
                    temp_arr(i) = this.temp{i};
                end
            end
        end
        
        % out_channel can be 1-4 or 'all' for read functions and 
        % only 1-4 for write
        function ret = readHeaterRange(this, out_channel)
            [cmd_str, isall] = getOutChannelQuery(this, 'RANGE', out_channel);
            resp_str = query(this.Device, cmd_str);
            if isall
                resp_split = strsplit(resp_str,';',...
                    'CollapseDelimiters',false);
                this.heater_rng = cellfun(@(s)sscanf(s, '%i'),...
                    resp_split,'UniformOutput',false);
                ret = this.heater_rng;
            else
                this.heater_rng{out_channel} = sscanf(resp_str, '%i');
                ret = this.heater_rng{out_channel};
            end 
        end
        
        function writeHeaterRange(this, out_channel, val)
            if isHeaterRangeOk(this, out_channel, val)
                cmd = sprintf('RANGE %i,%i', out_channel, val);
                fprintf(this.Device, cmd);
                % verify by reading the actual value
                readHeaterRange(this, out_channel);
            end
        end
        
        function ret = readSetpoint(this, out_channel)
            [cmd_str, isall] = getOutChannelQuery(this, 'SETP', out_channel);
            resp_str = query(this.Device, cmd_str);
            if isall
                resp_split = strsplit(resp_str,';',...
                    'CollapseDelimiters',false);
                this.setpoint = cellfun(@(s)sscanf(s, '%e'),...
                    resp_split,'UniformOutput',false);
                ret = this.setpoint;
            else
                this.setpoint{out_channel} = sscanf(resp_str, '%e');
                ret = this.setpoint{out_channel};
            end 
        end
        
        function writeSetpoint(this, out_channel)
            cmd = sprintf('SETP? %i', out_channel);
            fprintf(this.Device, cmd);
            % verify by reading the actual value
            readSetpoint(this, out_channel);
        end
        
        function ret = readInputSensorName(this)
            cmd_str = 'INNAME? A;INNAME? B;INNAME? C;INNAME? D';
            resp_str = query(this.Device, cmd_str);
            this.inp_sens_names = strtrim(strsplit(resp_str,';',...
                'CollapseDelimiters',false));
            ret = this.inp_sens_names;
        end
        
        function writeInputSensorName(this, in_channel, name)
            fprintf(this.Device, ['INNAME ',in_channel, name]);
            readInputSensorName(this)
            ch_n = inChannelToNumber(this, in_channel);
            if ~strcmpi(this.inp_sens_names{ch_n}, name)
                warning(['Name of input sensor ',in_channel,...
                    ' could not be changed'])
            end
        end
        
    end
    
    %% auxiliary method
    methods (Access=private)
        % check if the heater range code takes a proper value, which is
        % channel-dependent
        function bool = isHeaterRangeOk(~, out_channel, val)
            bool = false;
            switch out_channel
                case {1,2}
                    if val>=0 && val <=3
                        bool = true;
                    else
                        warning(['Wrong heater range. Heater range for '...
                            'channels 1 or 2 can '...
                            'take only integer values between 0 and 3'])
                    end
                case {3,4}
                    if val>=0 && val <=1
                        bool = true;
                    else
                        warning(['Wrong heater range. Heater range for '...
                            'channels 3 or 4 can '...
                            'take only values 1 or 2.'])
                    end
            end
        end
        
        % convert channel number and command name to the string that is
        % sent to instrument
        function [str, isall] = getOutChannelQuery(~, cmd, out_channel)
            out_ch_ok = false;
            isall = false;
            if isnumeric(out_channel)
                if out_channel==1 || out_channel==2 ||...
                        out_channel==3 || out_channel==4
                    str = sprintf('%s? %i', cmd, out_channel);
                    out_ch_ok = true;
                end
            elseif ischar(out_channel)
                if strcmpi(out_channel, 'all')
                    str = 'RANGE? 1;:RANGE? 2;:RANGE? 3;:RANGE? 4';
                    out_ch_ok = true;
                    isall = true;
                end
            end
            % issue error if the channel specifier is not 1-4 or 'all'
            if ~out_ch_ok
                error('out_channel can take values only 1-4 or ''all''');
            end
        end
        
        function num = inChannelToNumber(~,in_channel)
            switch in_channel
                case 'A'
                    num = int32(1);
                case 'B'
                    num = int32(2);
                case 'C'
                    num = int32(3);
                case 'D'
                    num = int32(4);
                otherwise
                    error('Input channel should be A, B, C or D.')
            end
        end
    end
    
    %% Set and get methods
    methods
        function str_cell = get.heater_rng_str(this)
            str_cell = {'','','',''};
            % Channels 1-2 and 3-4 have different possible states
            for i=1:4
                if ~isempty(this.heater_rng{i})
                    code = this.heater_rng{i};
                else
                    code=0;
                end
                if i<=2
                    switch code
                        case 0
                            str_cell{i} = 'Off';
                        case 1
                            str_cell{i} = 'Low';
                        case 2
                            str_cell{i} = 'Medium';
                        case 3
                            str_cell{i} = 'High';
                        otherwise
                    end
                else
                    switch code
                        case 0
                            str_cell{i} = 'Off';
                        case 1
                            str_cell{i} = 'On';
                        otherwise
                    end 
                end
            end
        end
        
        function str_cell = get.temp_str(this)
            str_cell = {'','','',''};
            for i=1:4
                if ~isempty(this.temp{i})
                    str_cell{i} = sprintf('%.3f %s', this.temp{i},...
                        this.temp_unit);
                end
            end
        end
        
        function set.temp_unit(this, val)
           if strcmpi(val,'K')||strcmpi(val,'C')
               this.temp_unit = upper(val);
           else
               warning(['Temperature unit needs to be K or C, ',...
                   'value has not been changed'])
           end
        end
    end
end

