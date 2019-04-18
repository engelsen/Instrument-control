% Generic logger that executes measFcn according to MeasTimer, stores the
% results and optionally continuously saves them. 
% measFcn should be a function with no arguments.  
% measFcn need to return a row vector of numbers in order to save the log
% in text format or display it. With other kinds of returned values the 
% log can still be recorded, but not saved or dispalyed.

classdef MyLogger < handle
    
    properties (Access = public)
        
        % Timer object
        MeasTimer = timer.empty()
        
        % Function that provides data to be recorded
        measFcn = @()0
        
        % MyLog object to store the recorded data
        Record = MyLog.empty()
        
        % Format for displaying readings (column name: value)
        disp_fmt = '\t%15s:\t%.5g'
    end
    
    properties (Access = public, SetObservable = true)
        save_cont = false
    end
    
    properties (SetAccess = protected, GetAccess = public)
        
        % If last measurement was succesful
        % 0-false, 1-true, 2-never measured
        last_meas_stat = 2 
    end
    
    events
        
        % Event that is triggered each time measFcn is successfully executed
        NewData
    end
    
    methods (Access = public)
        function this = MyLogger(varargin)
            P = MyClassParser(this);
            addParameter(P, 'log_opts', {}, @iscell);
            processInputs(P, this, varargin{:});
            
            this.Record = MyLog(P.Results.log_opts{:});
                 
            % Create and confitugure timer
            this.MeasTimer = timer();
            this.MeasTimer.BusyMode = 'drop';
            
            % Fixed spacing mode of operation does not follow the
            % period very well, but is robust with respect to
            % function execution delays
            this.MeasTimer.ExecutionMode = 'fixedSpacing';
            this.MeasTimer.TimerFcn = @this.loggerFcn;
        end
        
        function delete(this)
            
            % Stop and delete the timer
            try
                stop(this.MeasTimer);
            catch ME
                warning(['Could not stop measurement timer. Error: ' ...
                    ME.message]);
            end
            
            try
                delete(this.MeasTimer);
            catch ME
                warning(['Could not delete measurement timer. Error: ' ...
                    ME.message]);
            end
        end
        
        % Redefine start/stop functions for the brevity of use
        function start(this)
            start(this.MeasTimer);
        end
        
        function stop(this)
            stop(this.MeasTimer);
        end
        
        % Convert a part of log between Tmin and Tmax to MyTrace format and 
        % trigger a NewData event 
        function transferLog(this, Tmin, Tmax)
        end
        
        % Display reading
        function str = printReading(this, ind)
            if isempty(this.Record.timestamps)
                str = '';
                return
            end
            
            % Print the last reading if index is not given explicitly
            if nargin()< 2
                ind = length(this.Record.timestamps);
            end
            
            switch ind
                case 1
                    prefix = 'First reading ';
                case length(this.Record.timestamps)
                    prefix = 'Last reading ';
                otherwise
                    prefix = 'Reading ';
            end
            
            str = [prefix, char(this.Record.timestamps(ind)), newline];
            data_row = this.Record.data(ind, :);

            for i=1:length(data_row)
                if length(this.Record.data_headers)>=i
                    lbl = this.Record.data_headers{i};
                else
                    lbl = sprintf('data%i', i);
                end
                str = [str,...
                    sprintf(this.disp_fmt, lbl, data_row(i)), newline]; %#ok<AGROW>
            end
        end
    end
    
    methods (Access = protected)
        
        % Perform measurement and append point to the log
        function loggerFcn(this, ~, event)
            time = datetime(event.Data.time);
            try
                meas_result = this.measFcn();
                this.last_meas_stat = 1; % last measurement ok
            catch
                warning(['Logger cannot take measurement at time = ',...
                    datestr(time)]);
                this.last_meas_stat = 0; % last measurement not ok
            end
            
            if this.last_meas_stat == 1
                
                % Append measurement result together with time stamp
                appendData(this.Record, time, meas_result,...
                    'save', this.save_cont);
                triggerNewData(this);
            end
        end
        
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
        end
    end
    
    %% Set and get functions
    methods 
        function set.measFcn(this, val)
            assert(isa(val, 'function_handle'), ...
                '''measFcn'' must be a function handle.');
            this.measFcn = val;
        end
        
        function set.Record(this, val)
            assert(isa(val, 'MyLog'), '''Record'' must be a MyLog object')
            this.Record = val;
        end
        
        function set.save_cont(this, val)
            this.save_cont = logical(val);
        end
        
        function set.MeasTimer(this, val)
            assert(isa(val,'timer'), '''MeasTimer'' must be a timer object')
            this.MeasTimer = val;
        end
    end
end

