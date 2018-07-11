% Generic logger
classdef MyLogger
    properties 
        T; % Timer object
        save_cont = false;
        save_path = '';
        MeasFcn;
        %Trace object for storing data
        Trace=MyTrace();
    end
    
    methods
        function this = MyLogger(MeasFcn,varargin)
            this.MeasFcn = MeasFcn;
            
            this.T = timer(varargin{:});
            % Configure timer
            this.T.BusyMode = 'queue';
            this.T.ExecutionMode = 'FixedRate';
            this.T.TimerFcn = @(~,~)LoggerFcn(this); 
        end
        
        function delete(this)         
            %stop and delete the timer
            stop(this.T);
            delete(this.T);
        end
        
        function LoggerFcn(this)
            meas_result = this.MeasFcn();
        end
    end
end

