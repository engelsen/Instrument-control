classdef MyRsa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        rbw;
        start_freq;
        stop_freq;
        cent_freq;
        span;
        average_no;
        point_no;
        enable_avg;
        Trace;
        valid_points;
    end
    
    properties (Dependent=true)
        freq_vec;
    end
    
    methods
        function this=MyRsa(name,interface, address,varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            if this.enable_gui; initGui(this); end;
            
            %Valid point numbers for Tektronix 5103 and 5106. 
            %Depends on the RSA. Remove this in the future.
            this.valid_points=[801,2401,4001,10401];
            
            createCommandList(this);
            createCommandParser(this);
            switch interface
                case 'TCPIP'
                    connectTCPIP(this);
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
        function connectTCPIP(this)
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
            readProperty(this,'rbw','cent_freq','span','start_freq',...
                'stop_freq','enable_avg');
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
            set(this.Gui.cent_freq, 'Callback',...
                @(hObject, eventdata) cent_freqCallback(this, hObject,...
                eventdata));
            set(this.Gui.span, 'Callback',...
                @(hObject, eventdata) spanCallback(this, hObject,...
                eventdata));
            set(this.Gui.rbw, 'Callback',...
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
        
        function initDevice(this)            
            for i=1:this.command_no
                if this.CommandList.(this.command_names{i}).write_flag
                    write(this, ...
                        sprintf(this.CommandList.(this.command_names{i}).command,...
                        this.CommandList.(this.command_names{i}).default));
                    this.(this.command_names{i})=...
                        this.CommandList.(this.command_names{i}).default;
                end
            end
        end
        
        function reinitCallback(this, hObject, eventdata)
            reinitDevice(this);
            %Turns off indicator
            set(hObject,'Value',0);
        end
        
        function reinitDevice(this)
            openDevice(this);
            readStatus(this);
            initDevice(this);
            write(this,'INIT:CONT ON');
            closeDevice(this);
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
        
        function rbwCallback(this, hObject, eventdata)
            this.rbw=str2double(get(hObject,'String'))*1e3;
            openDevice(this);
            writeProperty(this,'rbw',this.rbw);
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
        
        function createCommandList(this)
            addCommand(this,'average_no','TRAC3:DPSA:AVER:COUN %d',...
                'default',1,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this, 'rbw','DPSA:BAND:RES %d Hz',...
                'default',1e3,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this, 'span', 'DPSA:FREQ:SPAN %d Hz',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,  'start_freq','DPSA:FREQ:STAR %d Hz',...
                'default',1e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this, 'stop_freq','DPSA:FREQ:STOP %d Hz',...
                'default',2e6,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,  'cent_freq','DPSA:FREQ:CENT %d Hz',...
                'default',1.5e6,'attributes',{{'numeric'}},'write_flag',true); 
            addCommand(this, 'point_no','DPSA:POIN:COUN P%d',...
                'default',10401,'attributes',{{'numeric'}},'write_flag',true);
            addCommand(this,'enable_avg','TRAC3:DPSA:COUN:ENABLE %d',...
                'default',0,'attributes',{{'numeric'}},'write_flag',true);
        end
        
        function fetchCallback(this, hObject, eventdata)
            %Fetches the data using the settings given. This function can
            %in principle be used in the future to add further fetch
            %functionality.
            switch get(hObject,'Tag')
                case 'fetch_single'
                    readSingle(this)
                    
            end
            set(this.Gui.fetch_single,'Value',0);
        end

        function enable_avgCallback(this, hObject, eventdata)
            this.enable_avg=get(hObject,'Value');
            openDevice(this)
            writeProperty(this,'enable_avg',this.enable_avg);
            closeDevice(this);
        end
                
        function readSingle(this)
            openDevice(this);
            readStatus(this);
            fwrite(this.Device, 'fetch:dpsa:res:trace3?');
            data = binblockread(this.Device,'float');
            x=this.freq_vec/1e6;
            unit_x='MHz';
            name_x='Frequency';
            
            closeDevice(this);
            %Calculates the power spectrum from the data, which is in dBm.
            %Output is in V^2/Hz
            power_spectrum = (10.^(data/10))/this.rbw*50*0.001;
            
            %Trace object is created containing the data and its units
            this.Trace=MyTrace('RsaData',x,power_spectrum,'unit_y',...
                '$\mathrm{V}^2/\mathrm{Hz}$','name_y','Power','unit_x',...
                unit_x,'name_x',name_x);
            %Plotting for test purposes - to be removed in the future
            figure
            this.Trace.plotTrace(gca);
        end
        
    end
    
    methods 
        %Set function for central frequency, changes gui to show central
        %frequency in MHz
        function set.cent_freq(this, cent_freq)
            this.cent_freq=cent_freq;
            if this.enable_gui
                set(this.Gui.cent_freq,'String',this.cent_freq/1e6);
            end
        end
        
        %Set function for rbw, changes gui to show rbw in kHz
        function set.rbw(this, rbw)
            assert(isnumeric(rbw) && rbw>0,'RBW must be a positive double');
            this.rbw=rbw;
            if this.enable_gui
                set(this.Gui.rbw,'String',this.rbw/1e3);
            end
        end
        %Set function for enable_avg, changes gui
        function set.enable_avg(this, enable_avg)
            assert(isnumeric(enable_avg),...
                'Flag for averaging must be a number')
            assert(enable_avg==1 || enable_avg==0,...
                'Flag for averaging must be 0 or 1')
            this.enable_avg=enable_avg;
            if this.enable_gui
                set(this.Gui.enable_avg,'Value',this.enable_avg)
            end
        end
        %Set function for span, changes gui to show span in MHz
        function set.span(this, span)
            assert(isnumeric(span) && span>0,...
                'Span must be a positive number');
            this.span=span;
            if this.enable_gui
                set(this.Gui.span,'String',this.span/1e6);
            end
        end
        

        %Set function for start frequency, changes gui to show start
        %frequency in MHz
        function set.start_freq(this, start_freq)
            assert(isnumeric(start_freq),'Start frequency must be a number');
            this.start_freq=start_freq;
            if this.enable_gui
                set(this.Gui.start_freq,'String',this.start_freq/1e6);
            end
        end
        
        %Set function for stop frequency, changes gui to show stop
        %frequency in MHz
        function set.stop_freq(this, stop_freq)
            assert(isnumeric(stop_freq),...
                'Stop frequency must be a number');
            this.stop_freq=stop_freq;
            if this.enable_gui
                set(this.Gui.stop_freq,'String',this.stop_freq/1e6)
            end
        end
        
        %Set function for average number, also changes GUI
        function set.average_no(this, average_no)
            assert(isnumeric(average_no),'Number of averages must be a number')
            assert(logical(mod(average_no,1))==0 && average_no>0,...
                'Number of averages must be a positive integer')
            this.average_no=average_no;
            if this.enable_gui
                set(this.Gui.average_no,'String',this.average_no);
            end
        end
        
        %Set function for point number, checks it is valid and changes GUI
        function set.point_no(this, point_no)
            bool=ismember(point_no,this.valid_points);
            if bool
                this.point_no=point_no;
                if this.enable_gui
                    ind=strcmp(get(this.Gui.point_no,'String'),...
                        num2str(point_no));
                    set(this.Gui.point_no,'Value',find(ind));
                end
            else
               error('Invalid number of points chosen for RSA')
            end
        end

        
    end
    methods
        %Generates a vector of frequencies between the start and stop
        %frequency of length equal to the point number
        function freq_vec=get.freq_vec(this)
           freq_vec=linspace(this.start_freq,this.stop_freq,...
               this.point_no) ;
        end
    end
        
end

