classdef MyNa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        ifbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        power;
        Trace;
    end

    methods
        function this=MyNa(name, interface, address, varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            createCommandList(this);
            createCommandParser(this);
            if this.enable_gui; initGui(this); end
        end
        
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
            set(this.Gui.reinit, 'Callback',...
                @(hObject, eventdata) reinitCallback(this, hObject,...
                eventdata));
            set(this.Gui.start_freq, 'Callback',...
                @(hObject, eventdata) start_freqCallback(this, hObject,...
                eventdata));
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
        
        function start_freqCallback(this, hObject, eventdata)
            this.start_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'start_freq',this.start_freq);
            readStatus(this);
            closeDevice(this);
        end
        
        function stop_freqCallback(this, hObject, eventdata)
            this.stop_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'stop_freq',this.stop_freq);
            readStatus(this);
            closeDevice(this);
        end
        
        function cent_freqCallback(this, hObject, eventdata)
            this.cent_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'cent_freq',this.cent_freq);
            readStatus(this);
            closeDevice(this);
        end
        function spanCallback(this, hObject, eventdata)
            this.span=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'span',this.span);
            readStatus(this)
            closeDevice(this);
        end
        
        function ifbwCallback(this, hObject, eventdata)
            this.ifbw=str2double(get(hObject,'String'))*1e3;
            openDevice(this);
            writeProperty(this,'ifbw',this.ifbw);
            closeDevice(this);
        end
        
        function average_noCallback(this, hObject, eventdata)
            this.average_no=str2double(get(hObject,'String'));
            %Writes the average_no to the device only if averaging is
            %enabled
            openDevice(this);
            writeProperty(this,'average_no',this.average_no);
            closeDevice(this);
        end
        
        
    end
end
