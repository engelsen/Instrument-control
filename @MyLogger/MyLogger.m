% Generic logger that executes MeasFcn according to MeasTimer, stores the
% results and possibly continuously saves them. MeasFcn should be a
% function with no arguments.
classdef MyLogger
    properties
        MeasTimer; % Timer object
        save_cont = false;
        save_file = '';
        MeasFcn;
    end
    
    properties (SetAccess=protected, GetAccess=public)
        Trace = MyTrace(); % Trace object for communication with Daq
        timestamps = []; % Times at which data was aqcuired
        data = []; % Stored cell array of measurements
    end
    
    methods
        function this = MyLogger(MeasFcn,varargin)
            this.MeasFcn = MeasFcn;            
            % Create and confitugure timer
            this.MeasTimer = timer(varargin{:});
            this.MeasTimer.BusyMode = 'queue';
            this.MeasTimer.ExecutionMode = 'FixedRate';
            this.MeasTimer.TimerFcn = @(~,event)LoggerFcn(this,event); 
        end
        
         function delete(this)         
             %stop and delete the timer
             stop(this.T);
             delete(this.T);
         end
        
        function LoggerFcn(this, event)
            % MeasFcn returns a single value or a row of values
            time = datetime(event.Data.time);
            meas_result = this.MeasFcn();
            % append the data point together with time stamp
            this.timestamps=[this.timestamps; time];
            this.data={this.data, meas_result};
            % save the point to file if continuous saving is enabled
            if this.save_cont
                fid = fopen(this.save_file,'a');
                fprintf('%i',int64(posixtime(time)));
                fprintf('%24.14e', meas_result);
                fclose(fid);
            end
        end
        
        function saveLog(this)
            fid = fopen(this.save_file,'r');
            fclose(fid);
        end
        
        function start(this)
            start(this.T)
        end
        
        function stop(this)
            stop(this.T)
        end
    end
end

