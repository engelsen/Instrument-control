% Spectrum analyzer based on Zurich Instruments UHFLI or MFLI

classdef MyZiScopeFt < MyZiLi & MyDataSource
    
    properties (Access=public)
        
    end
    
    properties (GetAccess=public, SetAccess={?MyClassParser})
        n_scope=1 % number of scope node
        
        % Input numbers between 1 and 148 correspond to various signals 
        % including physical inputs, outputs, demodulator channels and 
        % results of arthmetic operations. See the LabOne user interface 
        % for the complete list of choices and corresponding numbers.
        signal_in=1 
    end
    
    properties (Access=private)
         scope_module % 'handle' (in quotes) to a ZI software scope module 
         PollTimer    % Timer that regularly reads data drom the scope
         TmpTrace     % Temporary variable used for averaging
    end
    
    properties (Dependent=true)
        scope_path
        
        scope_rate % samples/sec
        fft_rbw % Resolution bandwidth of fourier transform
    end
    
    events
        NewWaves % Triggered when 
    end
    
    methods (Access=public)
        
        function this = MyZiScopeFt(dev_serial, varargin)
            this=this@MyZiLi();
            
            P=MyClassParser(this);
            addRequired(P, dev_serial, @ischar)
            % Poll timer period
            addParameter(P,'poll_period',0.042,@isnumeric);
            processInputs(P, this, dev_serial, varargin{:});
            
            % Trace object in this case is directly used for averaging
            this.Trace=MyAvgTrace(...
                'name_x','Time',...
                'unit_x','s',...
                'name_y','Magnitude r',...
                'unit_y','V');
            this.TmpTrace=MyTrace();
            
            this.PollTimer=timer(...
                'ExecutionMode','fixedSpacing',...
                'Period',P.Results.poll_period,...
                'TimerFcn',@(~,~)pollTimerCallback(this));
        end
        
        function delete(this)
            % delete function should never throw errors, so protect
            % statements with try-catch
            try
                stopPoll(this)
            catch
                warning(['Could not usubscribe from the scope node ', ...
                    'or stop the poll timer.'])
            end
            % Clear the module's thread.
            try 
                ziDAQ('clear', this.scope_module);
            catch
                warning('Could not clear the scope module.')
            end
            % Delete timers to prevent them from running indefinitely in
            % the case of program crash
            try
                delete(this.PollTimer)
            catch
                warning('Could not delete the poll timer.')
            end
        end
        
        
        function startPoll(this)
            % Configure hardware scope
            % Signal input
            ziDAQ('setInt', [this.scope_path,'/inputselect'], ...
                this.signal_in+1);
            % Disable segmented mode of data transfer. This mode is only 
            % useful if records longer than 5Mpts are required. 
            ziDAQ('setInt', [this.scope_path '/segments/enable'], 0);
            % Set sampling rate
            ziDAQ('setInt', [this.scope_path '/time'], 0);
            % Take continuous records
            ziDAQ('setInt', [this.scope_path '/single'], 0);
            % Disable the scope trigger
            ziDAQ('setInt', [this.scope_path '/trigenable'], 0);
            % The scope hold off time inbetween acquiring triggers (still
            % relevant if triggering is disabled).
            ziDAQ('setDouble', [this.scope_path '/trigholdoff'], 0.05);
            % Enable the scope
            ziDAQ('setInt', [this.scope_path '/enable'], 1);
            
            % Initialize and configure a Scope Module.
            this.scope_module = ziDAQ('scopeModule');
            % Do not average
            ziDAQ('set', this.scope_module, ...
                'scopeModule/averager/weight', 1);

            % Set the Scope Module's mode to return frequency domain data.
            ziDAQ('set', this.scope_module, 'scopeModule/mode', 3);
            % Use rectangular window function.
            ziDAQ('set', this.scope_module, 'scopeModule/fft/window', 0);
            ziDAQ('set', this.scope_module, 'scopeModule/fft/power', 1);
            ziDAQ('set', this.scope_module, ...
                'scopeModule/fft/spectraldensity', 1);
           
            ziDAQ('subscribe', this.scope_module, ...
                [this.scope_path '/wave']);
            
            ziDAQ('execute', this.scope_module);
            stop(this.PollTimer);
        end
        
        function stopPoll(this)
            stop(this.PollTimer);
            ziDAQ('finish', this.scope_module);
        end
        
        function pollTimerCallback(this)
            Data = ziDAQ('read', this.scope_module);
            if ziCheckPathInData(Data, [this.scope_path,'/wave'])
                % Get the list of scope waves recorded since the previous
                % poll
                new_waves=Data.(this.dev_id).scopes(this.n_scope).wave;
                % Add waves to the average trace
                for i=1:length(new_waves)
                    dt=new_waves{i}.dt;
                    n=new_waves{i}.totalsamples;
                    this.tmpTrace.x=linspace(0, 1/(2*dt), n);
                    this.tmpTrace.y=new_waves{i}.wave;
                    addAverage(this.Trace, this.tmpTrace);
                    if this.Trace.avg_count>=this.Trace.n_avg
                        triggerNewData(this);
                    end
                end
                notify(this, 'NewWaves');
            end
        end
        
        function Hdr=readHeader(this)
            Hdr=readHeader@MyZiLi(this);
        end
    end
    
    %% Set and get methods
    
    methods
        function val=get.scope_path(this)
            val=sprintf('/%s/scopes/%i',this.dev_id,this.n_scope+1);
        end
        
        function val=get.scope_rate(this)
            
        end
    end
end

