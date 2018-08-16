% Class for controlling Tektronix RSA5103 and RSA5106 spectrum analyzers 
classdef MyRsa < MyScpiInstrument
    %% Constructor and destructor
    methods (Access=public)
        function this=MyRsa(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            
            this.Trace.unit_x='Hz';
            this.Trace.unit_y='$\mathrm{V}^2/\mathrm{Hz}$';
            this.Trace.name_y='Power';
            this.Trace.name_x='Frequency';
        end
    end
    
    %% Private functions
    methods (Access=private)
        
        function createCommandList(this)
            % Resolution bandwidth (Hz)
            addCommand(this, 'rbw','DPX:BAND:RES',...
                'default',1e3,'str_spec','%e');
            % If the rbw is auto-set
            addCommand(this, 'auto_rbw','DPX:BAND:RES:AUTO',...
                'default',true,'str_spec','%b');
            addCommand(this, 'span', 'DPX:FREQ:SPAN',...
                'default',1e6,'str_spec','%e');
            addCommand(this,  'start_freq','DPX:FREQ:STAR',...
                'default',1e6,'str_spec','%e');
            addCommand(this, 'stop_freq','DPX:FREQ:STOP',...
                'default',2e6,'str_spec','%e');
            addCommand(this, 'cent_freq','DPX:FREQ:CENT',...
                'default',1.5e6,'str_spec','%e');
            % Initiate and abort data acquisition, don't take arguments
            addCommand(this, 'abort_acq','ABORt', 'access','w',...
                'str_spec','');
            addCommand(this, 'init_acq','INIT', 'access','w',...
                'str_spec','');
            % Continuous triggering
            addCommand(this, 'init_cont','INIT:CONT','default',true,...
                'str_spec','%b');
            % Number of points in trace
            addCommand(this, 'point_no','DPSA:POIN:COUN',...
                'default',10401, 'val_list',{801,2401,4001,10401},...
                'str_spec','P%i');
            % Reference level (dB)
            addCommand(this, 'ref_level','INPut:RLEVel','default',0,...
                'str_spec','%e');
            % Display scale per division (dBm/div)
            addCommand(this, 'disp_y_scale','DISPlay:DPX:Y:PDIVision',...
                'default',10,'str_spec','%e');
            % Display vertical offset (dBm)
            addCommand(this, 'disp_y_offset','DISPLAY:DPX:Y:OFFSET',...
                'default',0,'str_spec','%e');
            
            % Parametric commands
            for i = 1:3
                i_str = num2str(i);
                % Display trace
                addCommand(this, ['disp_trace',i_str],...
                    ['TRAC',i_str,':DPX'],...
                    'default',false,'str_spec','%b');
                % Trace Detection
                addCommand(this, ['det_trace',i_str],...
                    ['TRAC',i_str,':DPX:DETection'],...
                    'val_list',{'AVER','AVERage','NEG','NEGative',...
                    'POS','POSitive'},...
                    'default','AVER','str_spec','%s');
                % Trace Function
                addCommand(this, ['func_trace',i_str],...
                    ['TRAC',i_str,':DPX:FUNCtion'],...
                    'val_list',{'AVER','AVERage','HOLD','NORM','NORMal'},...
                    'default','AVER','str_spec','%s');
                % Number of averages
                addCommand(this, ['average_no',i_str],...
                    ['TRAC',i_str,':DPX:AVER:COUN'],...
                    'default',1,'str_spec','%i');
                % Count completed averages
                addCommand(this, ['cnt_trace',i_str],...
                    ['TRACe',i_str,':DPX:COUNt:ENABle'],...
                    'default',false,'str_spec','%b');
            end
        end
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        
        function readSingle(this, n_trace)
            fetch_cmd = sprintf('fetch:dpsa:res:trace%i?', n_trace);  
            fwrite(this.Device, fetch_cmd);
            data = binblockread(this.Device,'float');
            readProperty(this, 'start_freq','stop_freq','point_no');
            x_vec=linspace(this.start_freq,this.stop_freq,...
                this.point_no);
            %Calculates the power spectrum from the data, which is in dBm.
            %Output is in V^2/Hz
            power_spectrum = (10.^(data/10))/this.rbw*50*0.001;
            %Trace object is created containing the data and its units
            this.Trace.x = x_vec;
            this.Trace.y = power_spectrum;

            %Trigger acquired data event (inherited from MyInstrument)
            triggerNewData(this);
        end
    end
end

