% Object for testing data acquisition and header collection functionality

classdef MyDummyInstrument < MyInstrument & MyDataSource
    
    properties (Access = public, SetObservable = true)
        point_no = 1000
        
        trace_type = 'zero'
    end
    
    methods (Access = public)
        function this = MyDummyInstrument()
            createCommandList(this);
        end
        
        function readTrace(this)
            
            % Generate a random trace with the length equal to point_no
            this.Trace.x = (0:this.point_no-1)/(this.point_no-1);
            this.Trace.y = rand(1, this.point_no);
            
            switch this.trace_type
                case 'zero'
                    
                    % Do nothing
                case 'exp'
                    
                    % Add exponential "signal"
                    a = 5+rand();
                    b = 10*rand();
                    
                    sig = a*exp(-b*this.Trace.x);
                    
                    this.Trace.y = this.Trace.y + sig;
                case 'lorentz'
                    
                    % Add lorentzian "signal"
                    a = 10+rand();
                    b = 10*rand();
                    x0 = rand();
                    dx = 0.05*rand();
                    
                    sig = a-b*dx^2./((this.Trace.x-x0).^2+dx^2);
                    
                    this.Trace.y = this.Trace.y + sig(:);
                otherwise
                    error(['Unsupported trace type ' this.trace_type])
            end
            
            triggerNewData(this);
        end
        
        function Lg = createLogger(this, varargin)
            function x = getRandomMeasurement()
                sync(this);
                x = this.cmd3;
            end

            Lg = MyLogger(varargin{:}, 'MeasFcn', @getRandomMeasurement);
            
            Lg.Record.data_headers = {'random 1', 'random 2', ...
                'random 3', 'random 4', 'random 5'};
        end
        
        function idn(this)
            this.idn_str = 'dummy';
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % cmd1 is read and write accessible, it represents a paramter
            % which we can set and which does not change unless we set it
            addCommand(this, 'cmd1', ...
                'readFcn',  @()this.cmd1, ...
                'writeFcn', @(x)fprintf('cmd 1 write %e\n', x), ...
                'default',  rand());
            
            addCommand(this, 'cmd2', ...
                'readFcn',  @()rand(), ...
                'info',     'read only scalar');
            
            % cmd3 is a read only vector
            addCommand(this, 'cmd3', ...
                'readFcn',  @()rand(1,5), ...
                'info',     'read only vector');
        end
    end
    
    methods 
        function set.trace_type(this, val)
            assert(strcmpi(val, 'zero')|| ...
                strcmpi(val, 'exp')|| ...
                strcmpi(val, 'lorentz'), ...
                'Trace type must be ''zero'', ''exp'' or ''lorentz''.')
            this.trace_type = lower(val);
        end
    end
end

