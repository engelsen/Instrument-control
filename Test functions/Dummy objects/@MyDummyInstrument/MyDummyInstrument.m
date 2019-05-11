% Object for testing data acquisition and header collection functionality

classdef MyDummyInstrument < MyInstrument & MyDataSource
    
    properties (Access = public)
        point_no = 1000
    end
    
    methods (Access = public)
        function this = MyDummyInstrument()
            createCommandList(this);
        end
        
        function readTrace(this)
            
            % Generate a random trace with the length equal to point_no
            this.Trace.x = 1:this.point_no;
            this.Trace.y = rand(1, this.point_no);
            
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
end

