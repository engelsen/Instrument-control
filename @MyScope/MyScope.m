classdef MyScope <MyInstrument
    properties (Access=public)
        channel;
    end
    
    methods (Access=public)
        function this=MyScope(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            if this.enable_gui; initGui(this); end
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
                results.x_zero+results.x_step*(n_points-1),n_points);
            this.Trace=MyTrace('name','ScopeTrace','x',x,'y',y,'unit_x',results.unit_x(2),...
                'unit_y',results.unit_y(2),'name_x','Time','name_y','Voltage');
            %Triggers the event for acquired data
            triggerNewData(this);
        end
        
        function channel_selectCallback(this, hObject, ~)
            this.channel=get(hObject,'Value');
        end
        
        function fetch_singleCallback(this,~,~)
            readTrace(this);
        end
        
        function cont_readCallback(this, hObject, ~)
            while get(hObject,'Value')
                readTrace(this);
                pause(1);
            end
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            addCommand(this,'channel','DATa:SOUrce CH','default',1,...
                'classes',{'numeric'},'attributes',{'integer'},...
                'access','rw');
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
        
        function initGui(this)
            set(this.Gui.channel_select, 'Callback',...
                @(hObject, eventdata) channel_selectCallback(this, ...
                hObject,eventdata));
            set(this.Gui.fetch_single, 'Callback',...
                @(hObject, eventdata) fetch_singleCallback(this, ...
                hObject,eventdata));
            set(this.Gui.cont_read, 'Callback',...
                @(hObject, eventdata) cont_readCallback(this, ...
                hObject,eventdata));
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
            %Sets the gui if the gui is enabled
            if this.enable_gui
                set(this.Gui.channel_select,'Value',this.channel);
            end
        end
    end
end