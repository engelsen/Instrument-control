% Generic logger that executes MeasFcn according to MeasTimer, stores the
% results and optionally continuously saves them. 
% MeasFcn should be a function with no arguments.  
% MeasFcn need to return a row vector of numbers in order to save the log
% in text format or display it. With other kinds of returned values the 
% log can still be recorded, but not saved or dispalyed.

classdef MyLogger < handle
    
    properties (Access = public)
        
        % Timer object
        MeasTimer
        
        % Function that provides data to be recorded
        MeasFcn = @()0
        
        save_cont = false
        
        % MyLog object to store the recorded data
        Record
    end
    
    properties (SetAccess = protected, GetAccess = public)
        
        % If last measurement was succesful
        % 0-false, 1-true, 2-never measured
        last_meas_stat = 2 
    end
    
    events
        
        % Event that is triggered each time MeasFcn is successfully executed
        NewData
    end
    
    methods (Access = public)
        function this = MyLogger(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            this.Record = MyLog(P.unmatched_nv{:});
                 
            % Create and confitugure timer
            this.MeasTimer = timer();
            this.MeasTimer.BusyMode = 'drop';
            
            % Fixed spacing mode of operation does not follow the
            % period very well, but is robust with respect to
            % function execution delays
            this.MeasTimer.ExecutionMode = 'fixedSpacing';
            this.MeasTimer.TimerFcn = @(~,event)LoggerFcn(this,event);
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
    end
    
    methods (Access = protected)
        
        % Perform measurement and append point to the log
        function LoggerFcn(this, event)
            time = datetime(event.Data.time);
            try
                meas_result = this.MeasFcn();
                this.last_meas_stat=1; % last measurement ok
            catch
                warning(['Logger cannot take measurement at time = ',...
                    datestr(time)]);
                this.last_meas_stat=0; % last measurement not ok
            end
            
            if this.last_meas_stat==1
                
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
        function set.MeasFcn(this, val)
            assert(isa(val,'function_handle'), ...
                '''MeasFcn'' must be a function handle.');
            this.MeasFcn=val;
        end
        
        function set.Record(this, val)
            assert(isa(val,'MyLog'), '''Record'' must be a MyLog object')
            this.Record=val;
        end
        
        function set.save_cont(this, val)
            this.save_cont=logical(val);
        end
        
        function set.MeasTimer(this, val)
            assert(isa(val,'timer'), '''MeasTimer'' must be a timer object')
            this.MeasTimer=val;
        end
    end
end

