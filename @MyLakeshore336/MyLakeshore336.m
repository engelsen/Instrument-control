% Class communication with Lakeshore Model 336 temperature controller.

classdef MyLakeshore336 < MyScpiInstrument & MyCommCont 
    properties (SetAccess = protected, GetAccess = public)
        
        % Temperature unit, K or C. This variable should be set 
        % before the command list is created.
        temp_unit = 'K' 
    end
    
    properties (Constant = true)
        
        % Correspondence lists for numeric codes in parameter values. 
        % Indexing starts from 0. These lists are for information only.
        
        % Values for the output mode, out_mode_n(1). 
        out_mode_list = {'Off', 'Closed loop PID', 'Zone', ...
            'Open loop', 'Monitor out', 'Warmup supply'};
        
        % Control input, out_mode_n(2). 
        control_input_list = {'None', 'A', 'B', 'C', 'D'};
        
        % Heater ranges 
        heater12_range_list = {'Off','Low','Medium','High'};
        heater34_range_list = {'Off','On'};
    end
    
    methods (Access = public)
        function this = MyLakeshore336(varargin)
            this@MyCommCont(varargin{:});
            createCommandList(this);
        end
        
        % Create temperature logger
        function Lg = createLogger(this, varargin)
            function temp = readTemperature()
                sync(this);
                temp = [this.temp_a,this.temp_b,this.temp_c,this.temp_d];
            end

            Lg = MyLogger(varargin{:}, 'MeasFcn', @readTemperature);
            
            % Make column headers
            inp_ch = {'A', 'B', 'C', 'D'};
            headers = cell(1, 4);
            for i = 1:length(inp_ch)
                sens_name = sprintf('sens_name_%s', lower(inp_ch{i}));
                headers{i} = sprintf('T ch %s %s (%s)', inp_ch{i}, ...
                    sens_name, this.temp_unit);
            end
            
            if isempty(Lg.Record.data_headers)
                Lg.Record.data_headers = headers;
            end
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % Commands for the input channels
            inp_ch = {'A', 'B', 'C', 'D'};
            for i = 1:4
                nch = inp_ch{i};
                
                addCommand(this, ['sens_name_' lower(nch)], 'INNAME', ...
                    'read_ending',  ['? ' nch], ...
                    'write_ending', [' ' nch ',%s'], ...
                    'info',         ['Sensor name channel ' nch]);
                
                info = sprintf('Reading channel %s (%s)', nch, ...
                    this.temp_unit);
                
                addCommand(this, ['temp_' lower(nch)], ...
                    [this.temp_unit 'RDG'], ...
                    'format',       '%e', ... 
                    'access',       'r', ...
                    'read_ending',  ['? ' nch], ...
                    'info',         info);
            end
            
            % Commands for the output channels
            for i = 1:4
                nch = num2str(i);
                
                addCommand(this, ['setp_' nch], 'SETP', ...
                    'read_ending',  ['? ' nch], ...
                    'write_ending', [' ' nch ',%e'], ...
                    'info',         ['Output '  nch ' PID setpoint in ' ...
                        'preferred units of the sensor']);
                
                addCommand(this, ['out_mode_' nch], 'OUTMODE', ...
                    'read_ending',  ['? ' nch], ...
                    'write_ending', [' ' nch ',%i,%i,%i'], ...
                    'info',         ['Output '  nch ' settings: ' ...
                        '[mode, cntl_input, powerup_enable]'], ...
                    'default',      [0, 0, 0]);
                
                if i==1 || i==2
                    
                    % Outputs 1 and 2 have finer range control than than 3
                    % and 4
                    addCommand(this, ['range_' nch], 'RANGE', ...
                        'read_ending',  ['? ' nch], ...
                        'write_ending', [' ' nch ',%i'], ...
                        'info',         ['Output '  nch ' range ' ...
                            '0/1/2/3 -> off/low/medium/high'], ...
                        'value_list',   {0, 1, 2, 3});
                else
                    addCommand(this, ['range_' nch], 'RANGE', ...
                        'read_ending',  ['? ' nch], ...
                        'write_ending', [' ' nch ',%i'], ...
                        'info',         ['Output '  nch ' range ' ...
                            '0/1 -> off/on'], ...
                        'value_list',   {0, 1});
                end
            end
        end
    end
    
    methods
        function set.temp_unit(this, val)
            assert(strcmpi(val,'K') || strcmpi(val,'C'), ...
                'Temperature unit must be K or C.')
            
           this.temp_unit = upper(val);
        end
    end
end

