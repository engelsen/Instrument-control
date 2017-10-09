classdef MyRsa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        rbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        average_no;
        point_no;
    end
    
    methods
        function this=MyRsa(name,interface, address)
            this@MyInstrument(name, interface, address,'GuiRsa');
            initGui(this);
            createCommandList(this);
            createCommandParser(this);
            switch interface
                case 'TCPIP'
                    createTCPIP(this);
            end
            %Opens communications
            openDevice(this);
            %Finds the current status of the device
            readStatus(this);
            %Initializes the device
            initDevice(this);
            closeDevice(this);
        end
    end
    
    methods 
        function createTCPIP(this)
            buffer = 1000 * 1024;
            visa_brand = 'ni';
            visa_address_rsa = sprintf('TCPIP0::%s::inst0::INSTR',...
                this.address);
            this.Device=visa(visa_brand, visa_address_rsa,...
                'InputBufferSize', buffer,...
                'OutputBufferSize', buffer);
            set(this.Device,'InputBufferSize',1e6);
            set(this.Device,'Timeout',10);
        end
        
        function readProperty(this, varargin)
            for i=1:length(varargin)
                if ~isprop(this, varargin{i})
                    error('%s is not a property of the class',varargin{i})
                end
                %Finds the index of the % sign which indicates where the value
                %to be written is supplied
                ind=strfind(this.CommandList.(varargin{i}).command,'%');
                %Creates the correct read command 
                read_command=[this.CommandList.(varargin{i}).command(1:(ind-2)),'?'];
                %Reads the property from the device and stores it in the
                %correct place
                this.(varargin{i})=str2double(this.read(read_command));
            end
        end
        
        function readStatus(this)
            openDevice(this);
            readProperty(this,'rbw','cent_freq','span','start_freq','stop_freq');
            closeDevice(this);
        end
        
        function initGui(this)
            set(this.Gui.reinit, 'Callback',...
                @(hObject, eventdata) reinitCallback(this, hObject,...
                eventdata));
            set(this.Gui.point_no, 'Callback',...
                @(hObject, eventdata) point_noCallback(this, hObject,...
                eventdata));
            set(this.Gui.start_freq, 'Callback',...
                @(hObject, eventdata) start_freqCallback(this, hObject,...
                eventdata));
            set(this.Gui.stop_freq, 'Callback',...
                @(hObject, eventdata) stop_freqCallback(this, hObject,...
                eventdata));
            set(this.Gui.span, 'Callback',...
                @(hObject, eventdata) spanCallback(this, hObject,...
                eventdata));
            set(this.Gui.rbw, 'Callback',...
                @(hObject, eventdata) rbwCallback(this, hObject,...
                eventdata));
        end
        
        function initDevice(this)
            for i=1:this.command_no
                write(this, sprintf(this.CommandList.(this.command_names{i}).command,...
                    this.CommandList.(this.command_names{i}).default));
                this.(this.command_names{i})=...
                    this.CommandList.(this.command_names{i}).default;
            end
        end
        
        function reinitCallback(this, hObject, eventdata)
            openDevice(this);
            readStatus(this);
            initDevice(this);
            write(this,'INIT:CONT ON');
            closeDevice(this);
            %Turns off indicator
            set(hObject,'Value',0);
        end
        
        function point_noCallback(this, hObject, eventdata)
            value_list=get(hObject,'String');
            this.point_no=str2double(value_list{get(hObject,'Value')});
            openDevice(this);
            writeProperty(this,'point_no',this.point_no);
            readStatus(this);
            closeDevice(this);
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
        
        function spanCallback(this, hObject, eventdata)
            this.span=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'span',this.span);
            readStatus(this)
            closeDevice(this);
        end
        
        function rbwCallback(this, hObject, eventdata)
            this.rbw=str2double(get(hObject,'String'))*1e3;
            openDevice(this);
            writeProperty(this,'rbw',this.rbw);
            closeDevice(this);
        end
        
        function average_noCallback(this, hObject, eventdata)
            this.average_no=str2double(get(hObject,'String'));
            openDevice(this);
            writeProperty(this,'average_no',this.average_no);
            closeDevice(this);
        end
        
        function createCommandList(this)
            addCommand(this, 'average_no','TRAC3:DPSA:AVER:COUN %d',...
                1, {'numeric'});
            addCommand(this, 'rbw','DPSA:BAND:RES %d Hz',...
                1e3, {'numeric'});
            addCommand(this, 'span','DPSA:FREQ:SPAN %d Hz',...
                1e6, {'numeric'});
            addCommand(this, 'start_freq','DPSA:FREQ:STAR %d Hz',...
                1e6, {'numeric'});
            addCommand(this, 'stop_freq','DPSA:FREQ:STOP %d Hz',...
                2e6, {'numeric'});
            addCommand(this, 'cent_freq','DPSA:FREQ:CENT %d Hz',...
                1.5e6, {'numeric'}); 
            addCommand(this, 'point_no','DPSA:POIN:COUN P%d',...
                10401, {'numeric'});
        end
        
        
    end
    
    methods 
        %Set function for central frequency, changes gui to show central
        %frequency in MHz
        function set.cent_freq(this, cent_freq)
            this.cent_freq=cent_freq;
            set(this.Gui.cent_freq,'String',this.cent_freq/1e6);
        end
        
        %Set function for rbw, changes gui to show rbw in kHz
        function set.rbw(this, rbw)
            this.rbw=rbw;
            set(this.Gui.rbw,'String',this.rbw/1e3);
        end
        
        %Set function for span, changes gui to show span in MHz
        function set.span(this, span)
            this.span=span;
            set(this.Gui.span,'String',this.span/1e6);
        end
        

        %Set function for start frequency, changes gui to show start
        %frequency in MHz
        function set.start_freq(this, start_freq)
            this.start_freq=start_freq;
            set(this.Gui.start_freq,'String',this.start_freq/1e6)
        end
        
        %Set function for stop frequency, changes gui to show stop
        %frequency in MHz
        function set.stop_freq(this, stop_freq)
            this.stop_freq=stop_freq;
            set(this.Gui.stop_freq,'String',this.stop_freq/1e6)
        end
        
        function set.average_no(this, average_no)
            this.average_no=average_no;
            set(this.Gui.average_no,'String',this.average_no);
        end
        
        function set.point_no(this, point_no)
            point_list=get(this.Gui.point_no,'String');
            ind=find(strcmp(num2str(point_no),point_list));
            if ~isempty(ind)
                this.point_no=point_no;
                set(this.Gui.point_no,'Value',ind);
            else
               error('Invalid number of points chosen for RSA')
            end
        end
    end
end

