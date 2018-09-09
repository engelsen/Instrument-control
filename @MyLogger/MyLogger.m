% Generic logger that executes MeasFcn according to MeasTimer, stores the
% results and optionally continuously saves them. MeasFcn should be a
% function with no arguments. Saving functionality works properly if 
% MeasFcn returns a number or array of numbers, while intrinsically the 
% logger can store any kind of outputs.

classdef MyLogger < MyInputHandler
    properties (Access=public)
        MeasTimer % Timer object
        MeasFcn = @()0
        save_cont = false
        
        Log
        
        % Format for displaying last reading label: value
        disp_fmt = '%15s: %.2e'
    end
    
    properties (SetAccess=protected, GetAccess=public)
        % If last measurement was succesful
        % 0-false, 1-true, 2-never measured
        last_meas_stat = 2 
    end
    
    events
        % Event that is triggered each time MeasFcn is successfully executed
        NewData
    end
    
    methods
        function this = MyLogger(varargin)
            P=MyClassParser(this);
            P.KeepUnmatched=true;
            processInputs(P, this, varargin{:});
            
            this.Log=MyLog(varargin{:});
                 
            if ismember('MeasTimer', this.ConstructionParser.UsingDefaults)
                % Create and confitugure timer unless it was supplied
                % externally in varargin
                this.MeasTimer = timer();
                this.MeasTimer.BusyMode = 'drop';
                % Fixed spacing mode of operation does not follow the
                % period very well, but is robust with respect to
                % function execution delays
                this.MeasTimer.ExecutionMode = 'fixedSpacing';
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
                this.last_meas_stat=1; % last measurement ok
                triggerNewData(this);
            catch
                warning(['Logger cannot take measurement at time = ',...
                    datestr(time)]);
                this.last_meas_stat=0; % last measurement not ok
            end
            
            if this.last_meas_stat==1 
                % append measurement result together with time stamp
                appendPoint(this.Log, time, meas_result,...
                    'save', this.save_cont);
            end
        end
        
        % save the entire data record
        function saveLog(this)
            saveLog(this.Log)
        end
        
        function clearLog(this)
            clearLog(this.Log)
        end
        
        function start(this)
            start(this.MeasTimer);
        end
        
        function stop(this)
            stop(this.MeasTimer);
        end
        
        function str = dispLastReading(this)
            if isempty(this.timestamps)
                str = '';
            else
                str = ['Last reading ',char(this.timestamps(end)),newline];
                last_data = this.data{end};
                for i=1:length(last_data)
                    if length(this.data_headers)>=i
                        lbl = this.data_headers{i};
                    else
                        lbl = sprintf('data%i',i);
                    end
                    str = [str,...
                        sprintf(this.disp_fmt,lbl,last_data(i)),newline];
                end
            end
        end
    
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
        end
    end
end

