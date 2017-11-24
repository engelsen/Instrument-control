classdef MyRsa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        valid_points;
    end
    
    properties (Dependent=true)
        freq_vec;
    end
    
    %% Constructor and destructor
    methods (Access=public)
        function this=MyRsa(name,interface, address,varargin)
            this@MyInstrument(name, interface, address,varargin{:});
            if this.enable_gui; initGui(this); end
            
            createCommandList(this);
            createCommandParser(this);
            %Valid point numbers for Tektronix 5103 and 5106.
            %Depends on the RSA. Remove this in the future.
            this.valid_points=[801,2401,4001,10401];
            switch interface
                case 'TCPIP'
                    connectTCPIP(this);
            end
            
            %Tests if device is working.
            try
                openDevice(this);
                closeDevice(this);
            catch
                error(['Failed to open communications with device.',...
                    ' Check that the address and interface is correct.',...
                    ' Currently the address is %s and the interface is ',...
                    '%s.'],this.address,this.interface)
            end
            
            if this.enable_gui; setGuiProps(this); end
            %Opens communications
            openDevice(this);
            %Finds the current status of the device
            readAll(this);
            %Writes default parameters to the device
            writeProperty(this,'write_all_defaults',true);
            closeDevice(this);
        end
    end
    
    %% Private functions
    methods (Access=private)
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
        
        function setGuiProps(this)
            prop_names=fieldnames(this.CommandList);
            for i=1:length(prop_names)
                tag=prop_names{i};
                h_prop=findprop(this,tag);
                h_prop.GetMethod=@(this) getInstrProp(this, tag);
                h_prop.SetMethod=@(this, val) setInstrProp(this, tag, val);
                h_prop.Dependent=true;
            end
        end
        
        function setInstrProp(this, tag, val)
            switch this.Gui.(tag).Style
                case 'edit'
                    this.Gui.(tag).String=...
                        num2str(val/this.ConvFactors.(tag));
                case  'checkbox'
                    this.Gui.(tag).Value=val;
                case 'popupmenu'
                    ind=find(strcmp(this.Gui.(tag).String,num2str(val)));
                    this.Gui.(tag).Value=ind;
                otherwise
                    error('No appropriate GUI field was found for %s',tag);
            end
        end
        
        function val=getInstrProp(this, tag)
            switch this.Gui.(tag).Style
                case 'edit'
                    val=str2double(this.Gui.(tag).String)*...
                        this.ConvFactors.(tag);
                case 'checkbox'
                    val=this.Gui.(tag).Value;
                case 'popupmenu'
                    val=str2double(this.Gui.(tag).String(this.Gui.(tag).Value));
                otherwise
                    error('No appropriate GUI field was found for %s',tag);
            end
        end
        
        function initGui(this)
            this.Gui.Title.String{1}=sprintf('Real-Time Signal Analyzer %s',...
                this.name);
            this.Gui.reinit.Callback=@(hObject, eventdata)...
                reinitCallback(this, hObject,eventdata);
            this.Gui.point_no.Callback=@(hObject, eventdata)...
                point_noCallback(this, hObject,eventdata);
            this.Gui.start_freq.Callback=@(hObject, eventdata)...
                start_freqCallback(this, hObject, eventdata);
            this.Gui.stop_freq.Callback=@(hObject, eventdata)...
                stop_freqCallback(this, hObject,eventdata);
            this.Gui.cent_freq.Callback=@(hObject, eventdata)...
                cent_freqCallback(this, hObject, eventdata);
            this.Gui.span.Callback=@(hObject, eventdata)...
                spanCallback(this, hObject, eventdata);
            this.Gui.rbw.Callback=@(hObject, eventdata)...
                rbwCallback(this, hObject, eventdata);
            this.Gui.fetch_single.Callback=@(hObject, eventdata)...
                fetchCallback(this, hObject,eventdata);
            this.Gui.average_no.Callback=@(hObject, eventdata)...
                average_noCallback(this, hObject,eventdata);
            this.Gui.enable_avg.Callback=@(hObject, eventdata)...
                enable_avgCallback(this, hObject,eventdata);
        end
        

        
        function createCommandList(this)
            addCommand(this,'average_no','TRAC3:DPSA:AVER:COUN',...
                'default',1,'str_spec','i');
            addCommand(this, 'rbw','DPSA:BAND:RES',...
                'default',1e3,'str_spec','d')
            this.ConvFactors.rbw=1e3;
            addCommand(this, 'span', 'DPSA:FREQ:SPAN',...
                'default',1e6,'str_spec','d'},...
            this.ConvFactors.span=1e6;
            addCommand(this,  'start_freq','DPSA:FREQ:STAR',...
                'default',1e6,'str_spec','d')
            this.ConvFactors.start_freq=1e6;
            addCommand(this, 'stop_freq','DPSA:FREQ:STOP',...
                'default',2e6,'str_spec','d')
            this.ConvFactors.stop_freq=1e6;
            addCommand(this, 'cent_freq','DPSA:FREQ:CENT',...
                'default',1.5e6,'str_spec','d')
            this.ConvFactors.cent_freq=1e6;
            addCommand(this, 'point_no','DPSA:POIN:COUN P',...
                'default',10401,'str_spec','i','access','w');
            addCommand(this, 'enable_avg','TRAC3:DPSA:COUN:ENABLE',...
                'default',0,'str_spec','i');
            addCommand(this, 'read_cont','INIT:CONT','default',1,...
                'str_spec','i');
        end
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        
        function reinitDevice(this)
            openDevice(this);
            readAll(this);
            writeProperty(this, 'read_cont',1)
            closeDevice(this);
        end
        
        function readSingle(this)
            openDevice(this);
            
            fwrite(this.Device, 'fetch:dpsa:res:trace3?');
            data = binblockread(this.Device,'float');
            %Reads status at the end.
            readAll(this);
            closeDevice(this);
            x_vec=this.freq_vec/1e6;
            %Calculates the power spectrum from the data, which is in dBm.
            %Output is in V^2/Hz
            power_spectrum = (10.^(data/10))/this.rbw*50*0.001;
            %Trace object is created containing the data and its units
            setTrace(this.Trace,'name','RsaData','x',x_vec,'y',power_spectrum,...
                'unit_y','$\mathrm{V}^2/\mathrm{Hz}$','name_y','Power',...
                'unit_x','MHz','name_x','Frequency');

            %Trigger acquired data event (inherited from MyInstrument)
            triggerNewData(this);
        end
        
        function reinitCallback(this, hObject, ~)
            reinitDevice(this);
            %Turns off indicator
            set(hObject,'Value',0);
        end
        
        function point_noCallback(this, hObject, ~)
            value_list=get(hObject,'String');
            this.point_no=str2double(value_list{get(hObject,'Value')});
            openDevice(this);
            writeProperty(this,'point_no',this.point_no);
            readAll(this);
            closeDevice(this);
        end
        
        function start_freqCallback(this, hObject, ~)
            this.start_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'start_freq',this.start_freq);
            readAll(this);
            closeDevice(this);
        end
        
        function stop_freqCallback(this, hObject, ~)
            this.stop_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'stop_freq',this.stop_freq);
            readAll(this);
            closeDevice(this);
        end
        
        function cent_freqCallback(this, hObject, ~)
            this.cent_freq=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'cent_freq',this.cent_freq);
            readAll(this);
            closeDevice(this);
        end
        
        function spanCallback(this, hObject, ~)
            this.span=str2double(get(hObject,'String'))*1e6;
            openDevice(this);
            writeProperty(this,'span',this.span);
            readAll(this)
            closeDevice(this);
        end
        
        function rbwCallback(this, hObject, ~)
            this.rbw=str2double(get(hObject,'String'))*1e3;
            openDevice(this);
            writeProperty(this,'rbw',this.rbw);
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
        
        function fetchCallback(this, hObject, ~)
            %Fetches the data using the settings given. This function can
            %in principle be used in the future to add further fetch
            %functionality.
            switch get(hObject,'Tag')
                case 'fetch_single'
                    readSingle(this)
            end
            set(this.Gui.fetch_single,'Value',0);
        end
        
        function enable_avgCallback(this, hObject, ~)
            this.enable_avg=get(hObject,'Value');
            openDevice(this)
            writeProperty(this,'enable_avg',this.enable_avg);
            closeDevice(this);
        end
    end
    
%     %% Set functions
%     methods
%         %Set function for central frequency, changes gui to show central
%         %frequency in MHz
%         function set.cent_freq(this, cent_freq)
%             this.cent_freq=cent_freq;
%             if this.enable_gui
%                 set(this.Gui.cent_freq,'String',this.cent_freq/1e6);
%             end
%         end
%         
%         %Set function for rbw, changes gui to show rbw in kHz
%         function set.rbw(this, rbw)
%             assert(isnumeric(rbw) && rbw>0,'RBW must be a positive double');
%             this.rbw=rbw;
%             if this.enable_gui
%                 set(this.Gui.rbw,'String',this.rbw/1e3);
%             end
%         end
%         
%         %Set function for enable_avg, changes gui
%         function set.enable_avg(this, enable_avg)
%             assert(isnumeric(enable_avg),...
%                 'Flag for averaging must be a number')
%             assert(enable_avg==1 || enable_avg==0,...
%                 'Flag for averaging must be 0 or 1')
%             this.enable_avg=enable_avg;
%             if this.enable_gui
%                 set(this.Gui.enable_avg,'Value',this.enable_avg)
%             end
%         end
%         
%         %Set function for span, changes gui to show span in MHz
%         function set.span(this, span)
%             assert(isnumeric(span) && span>0,...
%                 'Span must be a positive number');
%             this.span=span;
%             if this.enable_gui
%                 set(this.Gui.span,'String',this.span/1e6);
%             end
%         end
%         
%         
%         %Set function for start frequency, changes gui to show start
%         %frequency in MHz
%         function set.start_freq(this, start_freq)
%             assert(isnumeric(start_freq),'Start frequency must be a number');
%             this.start_freq=start_freq;
%             if this.enable_gui
%                 set(this.Gui.start_freq,'String',this.start_freq/1e6);
%             end
%         end
%         
%         %Set function for stop frequency, changes gui to show stop
%         %frequency in MHz
%         function set.stop_freq(this, stop_freq)
%             assert(isnumeric(stop_freq),...
%                 'Stop frequency must be a number');
%             this.stop_freq=stop_freq;
%             if this.enable_gui
%                 set(this.Gui.stop_freq,'String',this.stop_freq/1e6)
%             end
%         end
%         
%         %Set function for average number, also changes GUI
%         function set.average_no(this, average_no)
%             assert(isnumeric(average_no),'Number of averages must be a number')
%             assert(logical(mod(average_no,1))==0 && average_no>0,...
%                 'Number of averages must be a positive integer')
%             this.average_no=average_no;
%             if this.enable_gui
%                 set(this.Gui.average_no,'String',this.average_no);
%             end
%         end
%         
%         %Set function for point number, checks it is valid and changes GUI
%         function set.point_no(this, point_no)
%             if ismember(point_no,this.valid_points)
%                 this.point_no=point_no;
%                 if this.enable_gui
%                     ind=strcmp(get(this.Gui.point_no,'String'),...
%                         num2str(point_no));
%                     set(this.Gui.point_no,'Value',find(ind));
%                 end
%             else
%                 error('Invalid number of points chosen for RSA')
%             end
%         end
%     end
%     
    %% Get functions
    methods
        %Generates a vector of frequencies between the start and stop
        %frequency of length equal to the point number
        function freq_vec=get.freq_vec(this)
            freq_vec=linspace(this.start_freq,this.stop_freq,...
                this.point_no) ;
        end
    end
    
end

