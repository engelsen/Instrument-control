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
        
        % Option for daily/weekly creation of a new log file 
        FileCreationInterval = duration.empty()
    end
    
    properties (SetAccess = protected, GetAccess = public)
        
        % If last measurement was succesful
        % 0-false, 1-true, 2-never measured
        last_meas_stat = 2 
    end
    
    events
        
        % Event that is triggered each time measFcn is successfully 
        % executed
        NewMeasurement
        
        % Event for transferring data to the collector
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
            if ~isempty(this.FileCreationInterval) && ...
                    isempty(this.Record.FirstSaveTime)
                
                % If run in the limited length mode, extend the record 
                % file name
                createLogFileName(this);
            end
            
            start(this.MeasTimer);
        end
        
        function stop(this)
            stop(this.MeasTimer);
        end
        
        % Trigger an event that transfers the data from one log channel 
        % to Daq
        function triggerNewData(this, varargin)
            
            % Since the class does not have Trace property, a Trace must be
            % supplied explicitly
            Trace = toTrace(this.Record, varargin{:});
            EventData = MyNewDataEvent('Trace',Trace, 'new_header',false);
            notify(this, 'NewData', EventData);
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
        
        % Generate a new file name for the measurement record
        function createLogFileName(this, path, name, ext)
            [ex_path, ex_name, ex_ext] = fileparts(this.Record.file_name);
            
            if ~exist('path', 'var')
                path = ex_path;
            end
            
            if ~exist('name', 'var')
                name = ex_name;
            end
            
            if ~exist('ext', 'var')
                if ~isempty(ex_ext)
                    ext = ex_ext;
                else
                    ext = this.Record.data_file_ext;
                end
            end
            
            % Remove the previous time stamp from the file name if exists,
            % as well as possible _n ending
            token = regexp(name, ...
                '\d\d\d\d-\d\d-\d\d \d\d-\d\d ([^(?:_\d)]*)', ...
                'tokens');
            if ~isempty(token)
                name = token{1}{1};
            end
            
            % Prepend a new time stamp
            name = [datestr(datetime('now'),'yyyy-mm-dd HH-MM '), name];
            
            file_name = fullfile(path, [name, ext]);

            % Ensure that the generated file name is unique
            file_name = createUniqueFileName(file_name);
            
            this.Record.file_name = file_name;
        end
    end
    
    methods (Access = protected)
        
        % Perform measurement and append point to the log
        function loggerFcn(this, ~, event)
            Time = datetime(event.Data.time);
            try
                meas_result = this.measFcn();
                this.last_meas_stat = 1; % last measurement ok
            catch ME
                warning(['Logger cannot take measurement at time = ',...
                    datestr(Time) '.\nError: ' ME.message]);
                this.last_meas_stat = 0; % last measurement not ok
                return
            end
            
            if this.Record.save_cont && ...
                    ~isempty(this.FileCreationInterval) && ...
                    ~isempty(this.Record.FirstSaveTime) && ...
                    (Time - this.Record.FirstSaveTime) >= ...
                        this.FileCreationInterval
                
                % Switch to a new data file
                createLogFileName(this);
            end
                
            % Append measurement result together with time stamp
            appendData(this.Record, Time, meas_result);
            notify(this, 'NewMeasurement');
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
        
        function set.MeasTimer(this, val)
            assert(isa(val,'timer'), '''MeasTimer'' must be a timer object')
            this.MeasTimer = val;
        end
    end
end

