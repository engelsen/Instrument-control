classdef MyScope <MyInstrument
    properties (Access=public)
        channel;
    end
    
    methods (Access=public)
        function this=MyScope(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
            switch interface
                case 'TCPIP'
                    connectTCPIP(this);
                case 'USB'
                    connectUSB(this);
            end
        end
        
        function readTrace(this)
            openDevice(this);
            %Sets the channel to be read
            writeProperty(this,'channel',this.channel);
            %Sets the encoding of the data
            fprintf(this.Device,'DATa:ENCdg ASCIi');
            % Reading the relevant parameters from the scope
            results = readProperty(this,'unit_y','unit_x',...
                'step_x','step_y','y_data','x_zero');
            closeDevice(this)
                        
            % Calculating the y data
            y= results.y_data*results.step_y; 
            n_points=length(y);

            % Calculating the x axis
            x=linspace(results.x_zero,...
                results.x_zero+results.step_x*(n_points-1),n_points);
            this.Trace=MyTrace('filename','ScopeTrace','x',x,'y',y,...
                'unit_x',char(results.unit_x),'unit_y',char(results.unit_y),...
                'name_x','Time','name_y','Voltage');
            %Triggers the event for acquired data
            triggerNewData(this);
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            addCommand(this,'channel','DATa:SOUrce','default',1,...
                'classes',{'numeric'},'attributes',{'integer'},...
                'access','rw','str_spec','CH%i');
            addCommand(this,'unit_x','WFMOutpre:XUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'unit_y','WFMOutpre:YUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'step_y','WFMOutpre:YMUlt','access','r',...
                'classes',{'numeric'});
            addCommand(this,'step_x','WFMOutpre:XINcr','access','r',...
                'classes',{'numeric'});
            addCommand(this,'x_zero','WFMOutpre:XZEro','access','r',...
                'classes',{'numeric'});
            addCommand(this,'y_data','CURVe','access','r',...
                'classes',{'numeric'});
        end
        
        function connectTCPIP(this)
            this.Device= visa('ni',...
                sprintf('TCPIP0::%s::inst0::INSTR',this.address));
            set(this.Device,'InputBufferSize',1e6);
            set(this.Device,'Timeout',2);
        end
        
        function connectUSB(this)
            this.Device=visa('ni',sprintf('USB0::%s::INSTR',this.address));
            set(this.Device,'InputBufferSize',1e6);
            set(this.Device,'Timeout',2);
        end
    end
    %% Set functions
    methods
        function set.channel(this, channel)
            if any(channel==1:4)
                this.channel=channel;
            else
                this.channel=1;
                warning('Select a channel from 1 to 4')
            end
        end
    end
end