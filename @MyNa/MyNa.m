classdef MyNa < MyInstrument
    properties (Access=public)
        ifbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        power;
    end
    
    methods (Access=public)
        function this=MyNa(name, interface, address, varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            
            switch interface
                case 'TCPIP'
                    connectTCPIP(this);
            end
            
            createCommandList(this);
            createCommandParser(this);
            if this.enable_gui; initGui(this); end
        end
        
        function start_freqCallback(this, hObject, ~)
            this.start_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'start_freq',this.start_freq);
            readStatus(this);
            closeDevice(this);
        end
        
        function stop_freqCallback(this, hObject, ~)
            this.stop_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'stop_freq',this.stop_freq);
            readStatus(this);
            closeDevice(this);
        end
        
        function cent_freqCallback(this, hObject, ~)
            this.cent_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'cent_freq',this.cent_freq);
            readStatus(this);
            closeDevice(this);
        end
        
        function spanCallback(this, hObject, ~)
            this.span=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'span',this.span);
            readStatus(this)
            closeDevice(this);
        end
        
        function ifbwCallback(this, hObject, ~)
            this.ifbw=str2double(get(hObject,'String'))*1e3;
            openDevice(this);
            writeProperty(this,'ifbw',this.ifbw);
            closeDevice(this);
        end
        
        function average_noCallback(this, hObject, ~)
            this.average_no=str2double(get(hObject,'String'));
            %Writes the average_no to the device only if averaging is
            %enabled
            openDevice(this);
            writeProperty(this,'average_no',this.average_no);
            closeDevice(this);
        end
        
        function fetchCallback(this, ~, ~)
            readSingle(this);
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            addCommand(this,'cent_freq','SENS:FREQ:CENT %d',...
                'default',1.5e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'start_freq','SENS:FREQ:START %d',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'stop_freq','SENS:FREQ:STOP %d',...
                'default',2e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'span','SENS:FREQ:SPAN %d',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'power','SOUR:POW:LEV:IMM:AMPL %d',...
                'default',1,'attributes',{{'numeric'}},'write_flag',true);
        end
        
        function initGui(this)
            this.Gui.reinit.Callback=@(hObject, eventdata)...
                reinitCallback(this, hObject,eventdata);
            this.Gui.start_freq.Callback=@(hObject, eventdata)...
                start_freqCallback(this, hObject,eventdata);
            set(this.Gui.stop_freq, 'Callback',...
                @(hObject, eventdata) stop_freqCallback(this, hObject,...
                eventdata));
            set(this.Gui.cent_freq, 'Callback',...
                @(hObject, eventdata) cent_freqCallback(this, hObject,...
                eventdata));
            set(this.Gui.span, 'Callback',...
                @(hObject, eventdata) spanCallback(this, hObject,...
                eventdata));
            set(this.Gui.ifbw, 'Callback',...
                @(hObject, eventdata) rbwCallback(this, hObject,...
                eventdata));
            set(this.Gui.fetch_single, 'Callback',...
                @(hObject, eventdata) fetchCallback(this, hObject,...
                eventdata));
            set(this.Gui.average_no, 'Callback',...
                @(hObject, eventdata) average_noCallback(this, hObject,...
                eventdata));
            set(this.Gui.enable_avg, 'Callback',...
                @(hObject, eventdata) enable_avgCallback(this, hObject,...
                eventdata));
        end
        
        function connectTCPIP(this)
            buffer = 1000 * 1024;
            visa_brand = 'ni';
            visa_address_rsa = sprintf('TCPIP0::%s::inst0::INSTR',...
                this.address);
            this.Device=visa(visa_brand, visa_address_rsa,...
                'InputBufferSize', buffer,...
                'OutputBufferSize', buffer);
            set(this.Device,'Timeout',10);
        end
        
        function readSingle(this)
            openDevice(this);
            % read trace data, assumes NA is set to ASC mode for data transfer
            this.Trace.x = str2double(strsplit(read(this,'SENS:FREQ:DATA?'),','));
            ydata = strsplit(query(this.Device,'CALC:DATA:FDAT?'),',');
            closeDevice(this);
            this.Trace.y = str2double(ydata(1:2:end));
            triggerNewData(this);
        end
    end
end
