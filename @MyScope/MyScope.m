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
                case 'visa'
                    this.Device=visa(this.Parser.Results.visa_brand,...
                        address);
                    configureDefaultVisa(this);
                case 'TCPIP'
                    connectTCPIP(this);
                case 'USB'
                    connectUSB(this);
                otherwise
                    error('Unknown interface');
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
            
            % valid numbers of points: 1000, 10000, 100000, 1000000, or 10000000
            addCommand(this, 'point_no','HORizontal:RECOrdlength',...
                'default',100000,...
                'str_spec','%i');
            % time scale in s per div
            addCommand(this, 'time_scale','HORizontal:SCAle',...
                'default',10E-3,...
                'str_spec','%e');
            addCommand(this, 'trig_source');
            addCommand(this, 'trig_lev')
            
            % Parametric commands
            for i = 1:4
                % coupling, AC, DC or GND
                i_str = num2str(i);
                addCommand(this,...
                    ['cpl',i_str],['CH',i_str,':COUP'],...
                    'default','DC',...
                    'str_spec','%s');              
                % impedances, 1MOhm or 50 Ohm
                addCommand(this,...
                    ['imp',i_str],['CH',i_str,':IMPedance'],...
                    'default','MEG',...
                    'str_spec','%s');
                % offset
                addCommand(this,...
                    ['offset',i_str],['CH',i_str,':OFFSet'],...
                    'default',0,...
                    'str_spec','%e');
                % scale, V/Div
                addCommand(this,...
                    ['scale',i_str],['CH',i_str,':SCAle'],...
                    'default',1,...
                    'str_spec','%e');
                % channel visible
            end
        end
        
        function connectTCPIP(this)
            this.Device= visa('ni',...
                sprintf('TCPIP0::%s::inst0::INSTR',this.address));
            configureDefaultVisa(this);
        end
        
        function connectUSB(this)
            this.Device=visa('ni',sprintf('USB0::%s::INSTR',this.address));
            configureDefaultVisa(this);
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