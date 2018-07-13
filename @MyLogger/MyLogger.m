% Generic logger that executes MeasFcn according to MeasTimer, stores the
% results and optionally continuously saves them. MeasFcn should be a
% function with no arguments. Saving functionality works properly if 
% MeasFcn returns a number or array of numbers, while intrinsically the 
% logger can store any kind of outputs.
classdef MyLogger < handle
    properties (Access=public)
        MeasTimer = []; % Timer object
        MeasFcn = @()0;
        save_cont = false;
        save_file = '';
        data_headers = {}; % Cell array of column headers
    end
    
    properties (SetAccess=protected, GetAccess=public)
        % Trace = MyTrace(); % Trace object for communication with Daq
        timestamps = []; % Times at which data was aqcuired
        data = []; % Stored cell array of measurements
        last_meas_stat = 2; % If last measurement was succesful
        % 0-false, 1-true, 2-never measured
        
        % format specifiers for data saving
        time_fmt = '%14.3f'; % Save time as posixtime up to ms precision
        data_field_width = '24';
        data_fmt = '%24.14e'; % Save data as reals with 14 decimal digits
    end
    
    methods
        function this = MyLogger(varargin)
            p=inputParser();
            % Ignore unmatched parameters
            p.KeepUnmatched = true;
            filt_varargin = parseClassInputs(p, this, varargin{:});
                 
            if ~isa(this.MeasTimer,'timer')
                % Create and confitugure timer unless it was supplied
                % externally in varargin
                this.MeasTimer = timer(filt_varargin{:});
                this.MeasTimer.BusyMode = 'queue';
                this.MeasTimer.ExecutionMode = 'FixedRate';
                this.MeasTimer.TimerFcn = @(~,event)LoggerFcn(this,event);
            end 
        end
        
        function delete(this)         
            %stop and delete the timer
            stop(this.MeasTimer);
            delete(this.MeasTimer);
        end
        
        function LoggerFcn(this, event)
            time = datetime(event.Data.time);
            try
                meas_result = this.MeasFcn();
                % append measurement result together with time stamp
                this.timestamps=[this.timestamps; time];
                this.data=[this.data, {meas_result}];
                this.last_meas_stat=1; % last measurement ok
            catch
                warning(['Logger cannot take measurement at time = ',...
                    datestr(time)]);
                this.last_meas_stat=0; % last measurement not ok
            end
            
            % save the point to file if continuous saving is enabled and
            % last measurement was succesful
            if this.save_cont&&(this.last_meas_stat==1)
                try
                    exstat = exist(this.save_file,'file');
                    if exstat==0
                        % if the file does not exist, create it and write
                        % header names
                        createFile(this.save_file);
                        fid = fopen(this.save_file,'w');
                        writeColumnHeaders(this, fid);
                    else
                        % otherwise open for appending
                        fid = fopen(this.save_file,'a');
                    end
                    fprintf(fid, this.TIME_FMT, posixtime(time));
                    fprintf(fid, this.data_fmt, meas_result);
                    fprintf(fid,'\r\n');
                    fclose(fid);
                catch
                    warning(['Logger cannot save data at time = ',...
                        datestr(time)]);
                    % Try closing fid in case it is still open
                    try
                        fclose(fid);
                    catch
                    end
                end
            end
        end
        
        % save the entire data record
        function saveLog(this)
            try
            	createFile(this.save_file);
                fid = fopen(this.save_file,'w');
                writeColumnHeaders(this, fid);
                for i=1:length(this.timestamps)
                    fprintf(fid, this.TIME_FMT,...
                        posixtime(this.timestamps(i)));
                    fprintf(fid, this.data_fmt,...
                        this.data{i});
                    fprintf(fid,'\r\n');
                end
                fclose(fid);
            catch
                warning('Data was not saved');
                % Try closing fid in case it is still open
                try
                    fclose(fid);
                catch
                end
            end
        end
        
        function clearLog(this)
            this.timestamps = [];
            this.data = [];
        end
               
        function writeColumnHeaders(this, fid)
            % write data headers to file if specified
            fprintf(fid, 'POSIX time [s]');
            for i=1:length(this.data_headers)
                fprintf(fid, ['%',this.data_field_width,'s'],...
                    this.data_headers{i});
            end
            fprintf(fid,'\r\n');
        end
        
        function start(this)
            start(this.MeasTimer);
        end
        
        function stop(this)
            stop(this.MeasTimer);
        end
    end
end
