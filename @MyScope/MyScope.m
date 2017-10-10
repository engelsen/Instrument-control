classdef MyScope <MyInstrument
    properties
        Trace;
        channel;
    end
    
    methods
        function this=MyScope(name, interface, address)
            this@MyInstrument(name, interface, address,'GuiScope');
            initGui(this);
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
        end
        
        function channel_selectCallback(this, hObject, eventdata)
            this.channel=get(hObject,'Value');
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
            set(this.Gui.channel_select,'Value',this.channel);
        end
        
        function readTrace(this)
            openDevice(this);
            fprintf(this.Device,['DATa:SOUrce CH',num2str(this.channel)]);
            dataSet.Source = strtrim(query(this.Device,'DATa:SOUrce?'));
            fprintf(this.Device,'DATa:ENCdg ASCIi');
            dataSet.format = strtrim(query(this.Device,'DATa:ENCdg?'));
            
            % Reading the units
            temp = strtrim(query(this.Device,'WFMOutpre:YUNit?'));
            dataSet.unit_y=temp(2);
            temp = strtrim(query(this.Device,'WFMOutpre:XUNit?'));
            dataSet.unit_x=temp(2);
            
            % Reading the vertical spacing between points
            step_y = str2num(query(this.Device,'WFMOutpre:YMUlt?'));
            
            % Reading the number of the points REMOVED BY NILS - WHY IS THIS NECESSARY?
            % JUST TAKE THE LENGTH OF Y AXIS DATA?
            % dataSet.n_points = str2num(query(this.Device,'WFMInpre:NR_Pt?'));
            
            % Reading the y axis data
            y= str2num(query(this.Device,'CURVe?'))*step_y;
            n_points=length(y);
            % Reading the horizontal spacing between points
            x_steps=str2num(query(this.Device,'WFMOutpre:XINcr?'));
            x_zero=str2num(query(this.Device,'WFMOutpre:XZEro?'));
            
            % calculating the x axis
            x=linspace(x_zero,x_zero+x_steps*n_points,n_points);
            closeDevice(this)
            plot(x,y)
        end
    end
end