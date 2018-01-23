classdef MyRsa < MyInstrument
    %% Constructor and destructor
    methods (Access=public)
        function this=MyRsa(interface, address,varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
            connectDevice(this, interface, address);
        end
    end
    
    %% Private functions
    methods (Access=private)
        
        function createCommandList(this)
            % Resolution bandwidth
            addCommand(this, 'rbw','DPSA:BAND:RES',...
                'default',1e3,'str_spec','%e');
            addCommand(this, 'span', 'DPSA:FREQ:SPAN',...
                'default',1e6,'str_spec','%e');
            addCommand(this,  'start_freq','DPSA:FREQ:STAR',...
                'default',1e6,'str_spec','%e');
            addCommand(this, 'stop_freq','DPSA:FREQ:STOP',...
                'default',2e6,'str_spec','%e');
            addCommand(this, 'cent_freq','DPSA:FREQ:CENT',...
                'default',1.5e6,'str_spec','%e');

            addCommand(this, 'point_no','DPSA:POIN:COUN',...
                'default',10401, 'val_list',{801,2401,4001,10401},...
                'str_spec','P%i');
            addCommand(this, 'read_cont','INIT:CONT','default',true,...
                'str_spec','%b');
            % Reference level
            % Display offset
            % display scale per division DISPlay:DPX:Y[:SCALe]:PDIVision
            % display vertical offset DISPLAY:DPX:Y[:SCALE]:OFFSET -12.5dBm
            
            % Parametric commands
            for i = 1:4
                i_str = num2str(i);
                % Display trace
                % Enable average
                addCommand(this, ['enable_avg',i_str],...
                    ['TRAC',i_str,':DPSA:COUN:ENABLE'],...
                    'default',false,'str_spec','%b');
                % Number of averages
                addCommand(this, ['average_no',i_str],...
                    ['TRAC',i_str,':DPSA:AVER:COUN'],...
                    'default',1,'str_spec','%i');
            end
        end
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        
        function readSingle(this)
            openDevice(this);  
            fwrite(this.Device, 'fetch:dpsa:res:trace3?');
            data = binblockread(this.Device,'float');
            closeDevice(this);
            
            x_vec=linspace(this.start_freq,this.stop_freq,...
                this.point_no);
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
    end
end

