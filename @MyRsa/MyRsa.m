classdef MyRsa < MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        valid_points;
        ConvFactors=struct();
    end
    
    properties (Dependent=true)
        freq_vec;
    end
    
    %% Constructor and destructor
    methods (Access=public)
        function this=MyRsa(interface, address,varargin)
            this@MyInstrument(interface, address,varargin{:});
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
            readProperty(this,'all');
            %Writes default parameters to the device
            writeProperty(this,'all',true);
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
            this.ConvFactors.average_no=1;
            addCommand(this, 'rbw','DPSA:BAND:RES',...
                'default',1e3,'str_spec','d')
            this.ConvFactors.rbw=1e3;
            addCommand(this, 'span', 'DPSA:FREQ:SPAN',...
                'default',1e6,'str_spec','d'),...
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
            readProperty(this,'all');
            writeProperty(this, 'read_cont',1)
            closeDevice(this);
        end
        
        function readSingle(this)
            openDevice(this);
            
            fwrite(this.Device, 'fetch:dpsa:res:trace3?');
            data = binblockread(this.Device,'float');
            %Reads status at the end.
            readProperty(this,'all');
            closeDevice(this);
            x_vec=this.freq_vec;
            %Calculates the power spectrum from the data, which is in dBm.
            %Output is in V^2/Hz
            power_spectrum = (10.^(data/10))/this.rbw*50*0.001;
            %Trace object is created containing the data and its units
            setTrace(this.Trace,'x',x_vec,'y',power_spectrum,...
                'unit_y','$\mathrm{V}^2/\mathrm{Hz}$','name_y','Power',...
                'unit_x','Hz','name_x','Frequency');

            %Trigger acquired data event (inherited from MyInstrument)
            triggerNewData(this);
        end
        
        function reinitCallback(this, hObject, ~)
            reinitDevice(this);
            %Turns off indicator
            set(hObject,'Value',0);
        end
        
        function point_noCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'point_no',this.point_no);
            readProperty(this,'all');
            closeDevice(this);
        end
        
        function start_freqCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'start_freq',this.start_freq);
            readProperty(this,'all');
            closeDevice(this);
        end
        
        function stop_freqCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'stop_freq',this.stop_freq);
            readProperty(this,'all');
            closeDevice(this);
        end
        
        function cent_freqCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'cent_freq',this.cent_freq);
            readProperty(this,'all');
            closeDevice(this);
        end
        
        function spanCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'span',this.span);
            readProperty(this,'all');
            closeDevice(this);
        end
        
        function rbwCallback(this, ~, ~)
            openDevice(this);
            writeProperty(this,'rbw',this.rbw);
            closeDevice(this);
        end
        
        function average_noCallback(this, ~, ~)
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
        
        function enable_avgCallback(this, ~, ~)
            openDevice(this)
            writeProperty(this,'enable_avg',this.enable_avg);
            closeDevice(this);
        end
    end
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

