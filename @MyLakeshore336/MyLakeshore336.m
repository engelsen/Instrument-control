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
        % output modes{{mode, cntl_inp, powerup_en},...}
        out_mode = {{[0,0,0]},{[0,0,0]},{[0,0,0]},{[0,0,0]}}; 
    end
    
    properties (SetAccess=private, GetAccess=public)
        % Correspondense lists. Indexing starts from 0
        inp_list = {'None','A','B','C','D'};
        out_mode_list = {'Off','Closed loop PID','Zone',...
            'Open loop','Monitor out','Warmup supply'};
        heater12_rng_list = {'Off','Low','Medium','High'};
        heater34_rng_list = {'Off','On'};
    end
    
    properties (Dependent=true)
        heater_rng_str % heater range
        temp_str % temperatures with measurement unit
        out_mode_str %
        cntl_inp_str %
        powerup_en_str %
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
            readHeaterRange(this);
            readSetpoint(this);
            readInputSensorName(this);
            readOutMode(this);
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
        
        % out_channel is 1-4, in_channel is A-D
        function ret = readHeaterRange(this)
            cmd_str = 'RANGE? 1;RANGE? 2;RANGE? 3;RANGE? 4';
            resp_str = query(this.Device, cmd_str);
            resp_split = strsplit(resp_str,';','CollapseDelimiters',false);
            this.heater_rng = cellfun(@(s)sscanf(s, '%i'),...
                resp_split,'UniformOutput',false);
            ret = this.heater_rng; 
        end
        
        function writeHeaterRange(this, out_channel, val)
            if isHeaterRangeOk(this, out_channel, val)
                cmd = sprintf('RANGE %i,%i', out_channel, val);
                fprintf(this.Device, cmd);
                % verify by reading the actual value
                readHeaterRange(this);
            end
        end
        
        function ret = readSetpoint(this)
            cmd_str = 'SETP? 1;SETP? 2;SETP? 3;SETP? 4';
            resp_str = query(this.Device, cmd_str);
            resp_split = strsplit(resp_str,';','CollapseDelimiters',false);
            this.setpoint = cellfun(@(s)sscanf(s, '%e'),...
                resp_split,'UniformOutput',false);
            ret = this.setpoint;
        end
        
        function writeSetpoint(this, out_channel, val)
            cmd_str = sprintf('SETP %i,%.3f', out_channel, val);
            fprintf(this.Device, cmd_str);
            % verify by reading the actual value
            readSetpoint(this);
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
        
        function ret = readOutMode(this)
            cmd_str = 'OUTMODE? 1;OUTMODE? 2;OUTMODE? 3;OUTMODE? 4';
            resp_str = query(this.Device, cmd_str);
            resp_split = strsplit(resp_str,';','CollapseDelimiters',false);
            this.out_mode = cellfun(@(s)sscanf(s, '%i,%i,%i'),...
                resp_split,'UniformOutput',false);
            ret = this.out_mode;
        end
        
        function writeOutMode(this,out_channel,mode,cntl_inp,powerup_en)
            cmd_str = sprintf('OUTMODE %i,%i,%i,%i',out_channel,...
                mode,cntl_inp,powerup_en);
            fprintf(this.Device, cmd_str);
            % verify by reading the actual value
            readOutMode(this);
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
                    ind = int32(this.heater_rng{i}+1);
                else
                    ind=0;
                end
                if i<=2
                    str_cell{i} = this.heater12_rng_list{ind};
                else
                    str_cell{i} = this.heater34_rng_list{ind}; 
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
        
        function str_cell = get.out_mode_str(this)
            str_cell = {'','','',''};
            try
                for i=1:4
                    ind = int32(this.out_mode{i}(1)+1);
                    str_cell{i} = this.out_mode_list{ind};
                end
            catch
                warning(['Output mode could not be interpreted ',...
                        'from code. Code should be between 0 and 5.'])
            end
        end
        
        function str_cell = get.cntl_inp_str(this)
            str_cell = {'','','',''};
            try
                for i=1:4
                    ind = int32(this.out_mode{i}(2)+1);
                    str_cell{i} = this.inp_list{ind};
                end
            catch
                warning(['Input channel could not be interpreted ',...
                        'from index. Index should be between 0 and 4.'])
            end
        end
        
        function str_cell = get.powerup_en_str(this)
            str_cell = {'','','',''};
            for i=1:4
                if this.out_mode{i}(3)
                    str_cell{i} = 'On';
                else
                    str_cell{i} = 'Off';
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

