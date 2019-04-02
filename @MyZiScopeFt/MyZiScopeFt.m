% Spectrum analyzer based on Zurich Instruments UHFLI or MFLI

classdef MyZiScopeFt < MyZiLi & MyDataSource
    
    properties (GetAccess=public, SetAccess={?MyClassParser})
        n_scope=1   % number of hardware scope
        n_ch=1      % number of scope channel
        
        % Input numbers between 1 and 148 correspond to various signals 
        % including physical inputs, outputs, demodulator channels and 
        % results of arthmetic operations. See the LabOne user interface 
        % for the complete list of choices and corresponding numbers.
        % This number is shifted by +1 compare to the hardware node
        % enumeration as usual.
        signal_in=1 
        
        % Deas time between scope frame acquisitions. Smaller time results 
        % in faster averaging but may not look nice during real time 
        % gui update.
        trigholdoff=0.02 % seconds
    end
    
    properties (Access=private)
         scope_module % 'handle' (in quotes) to a ZI software scope module 
         PollTimer    % Timer that regularly reads data drom the scope
         TmpTrace     % Temporary variable used for averaging
    end
    
    properties (Dependent=true)
        scope_path
        
        scope_rate      % samples/sec
        n_pt            % length of scope wave 
        fft_rbw         % Spacing between fft bins
    end
    
    events
        NewWave % Triggered when the scope acquires new waves 
    end
    
    methods (Access=public)
        
        function this = MyZiScopeFt(dev_serial, varargin)
            this=this@MyZiLi(dev_serial);
            
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
            path=sprintf('%s/channels/%i/inputselect', ...
                this.scope_path, this.n_ch);
            ziDAQ('setInt', path, this.signal_in-1);
            % Disable segmented mode of data transfer. This mode is only 
            % useful if records longer than 5Mpts are required. 
            ziDAQ('setInt', [this.scope_path '/segments/enable'], 0);
            % Take continuous records
            ziDAQ('setInt', [this.scope_path '/single'], 0);
            % Disable the scope trigger
            ziDAQ('setInt', [this.scope_path '/trigenable'], 0);
            % The scope hold off time inbetween acquiring triggers (still
            % relevant if triggering is disabled).
            ziDAQ('setDouble', [this.scope_path '/trigholdoff'], ...
                this.trigholdoff);
            % Enable the scope
            ziDAQ('setInt', [this.scope_path '/enable'], 1);
            
            % Initialize and configure a software Scope Module.
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
            start(this.PollTimer);
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
                    n=double(new_waves{i}.totalsamples);
                    % Calculate the frequency axis
                    this.TmpTrace.x=linspace(0, (1-1/n)/(2*dt), n);
                    this.TmpTrace.y=new_waves{i}.wave;
                    is_compl=addAverage(this.Trace, this.TmpTrace);
                    if is_compl && strcmpi(this.Trace.avg_type, 'lin')
                        triggerNewData(this);
                    end
                end
                notify(this, 'NewWave');
            end
        end
        
        function Hdr=readHeader(this)
            Hdr=readHeader@MyZiLi(this);
            addObjProp(Hdr, this, 'n_scope', 'comment', ...
                'Hardware scope number');
            addObjProp(Hdr, this, 'n_ch', 'comment', ...
                'Scope channel');
            addObjProp(Hdr, this, 'signal_in', 'comment', ...
                'Signal input number');
            addObjProp(Hdr, this, 'trigholdoff', 'comment', ...
                ['(s), the scope hold off time inbetween acquiring ' ...
                'triggers']);
            addParam(Hdr, this.name, 'poll_period', ...
                this.PollTimer.Period, 'comment', '(s)');
        end
    end
    
    %% Set and get methods
    
    methods
        function val=get.scope_path(this)
            val=sprintf('/%s/scopes/%i',this.dev_id,this.n_scope-1);
        end
        
        function val=get.scope_rate(this)
            tn=ziDAQ('getDouble', [this.scope_path '/time']);
            val=this.clockbase/(2^tn);
        end
        
        function set.scope_rate(this, val)
            tn=round(log2(this.clockbase/val));
            % Trim to be withn 0 and 16
            tn=max(0,tn);
            tn=min(tn, 16);
            ziDAQ('setDouble', [this.scope_path '/time'], tn);
            clearData(this.Trace);
            notify(this, 'NewSetting');
        end
        
        function val=get.fft_rbw(this)
            l=length(this.Trace.x);
            if l>=2
                val=this.Trace.x(2)-this.Trace.x(1);
            else
                val=Inf;
            end
        end
        
        function val=get.n_pt(this)
            val=ziDAQ('getDouble', [this.scope_path '/length']);
        end
        
        function set.n_pt(this, val)
            ziDAQ('setDouble', [this.scope_path '/length'], val);
            clearData(this.Trace);
            notify(this, 'NewSetting');
        end
    end
end
