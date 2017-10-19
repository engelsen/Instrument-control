classdef MyScope <MyInstrument
    properties
        Trace;
        channel;
    end
    
    events
        AcquiredTrace;
    end
    
    methods
        function this=MyScope(name, interface, address, varargin)
            this@MyInstrument(name, interface, address, varargin{:});
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
        
        function channel_selectCallback(this, hObject, eventdata)
            this.channel=get(hObject,'Value');
        end
        
        function fetch_singleCallback(this,hObject,eventdata)
            readTrace(this);
        end
        
        function cont_readCallback(this, hObject, eventdata)
            while get(hObject,'Value')
                readTrace(this)
            end
        end
        
         function createCommandList(this)
             addCommand(this,'channel','DATa:SOUrce CH%d','default',1,...
                 'attributes',{{'numeric'}},'write_flag',true);
         end
    end
    
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
        
        function readTrace(this)
            openDevice(this);
            %Sets the channel to be read
            writeProperty(this,'channel',this.channel);
            %Sets the encoding of the data
            fprintf(this.Device,'DATa:ENCdg ASCIi');
            
            % Reading the units of x and y
            unit_y = strtrim(query(this.Device,'WFMOutpre:YUNit?'));
            unit_x = strtrim(query(this.Device,'WFMOutpre:XUNit?'));

            % Reading the vertical spacing between points
            step_y = str2num(query(this.Device,'WFMOutpre:YMUlt?'));
            
            % Reading the y axis data
            y= str2num(query(this.Device,'CURVe?'))*step_y;
            n_points=length(y);
            % Reading the horizontal spacing between points
            x_step=str2num(query(this.Device,'WFMOutpre:XINcr?'));
            %Reads where the zero of the x-axis is
            x_zero=str2num(query(this.Device,'WFMOutpre:XZEro?'));
            
            % Calculating the x axis
            x=linspace(x_zero,x_zero+x_step*(n_points-1),n_points);
            closeDevice(this)
            this.Trace=MyTrace('name','ScopeTrace','x',x,'y',y,'unit_x',unit_x(2),...
                'unit_y',unit_y(2),'name_x','Time','name_y','Voltage');
            %Triggers the event for acquired data
            triggerAcquiredData(this);
            
            this.Trace.plotTrace(this.plot_handle);
        end
    end
end