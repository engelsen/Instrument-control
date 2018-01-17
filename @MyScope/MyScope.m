classdef MyScope <MyInstrument
      methods (Access=public)
        function this=MyScope(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
            try
                switch interface
                    case 'visa'
                        this.Device=visa(this.Parser.Results.visa_brand,...
                            address);
                        configureDefaultVisa(this);
                    case 'TCPIP'
                        connectTCPIP(this);
                    case 'USB'
                        connectUSB(this);
                    otherwise
                        warning('Unknown interface, device is not connected');
                end
            catch
                warning('Device is not connected');
            end
        end
        
        function readTrace(this)
            openDevice(this);
            %Sets the channel to be read
            writeProperty(this,'channel',this.channel);
            %Sets the encoding of the data
            fprintf(this.Device,'DATa:ENCdg ASCIi');
            % Reading the relevant parameters from the scope
            readProperty(this,'unit_y','unit_x',...
                'step_x','step_y','y_data','x_zero');
            this.y_data = str2num(this.y_data);
            closeDevice(this)
                        
            % Calculating the y data
            y = this.y_data*this.step_y; 
            n_points=length(y);

            % Calculating the x axis
            x = linspace(this.x_zero,...
                this.x_zero+this.step_x*(n_points-1),n_points);
            
            this.Trace.x = x;
            this.Trace.y = y;
            this.Trace.unit_x = char(this.unit_x);
            this.Trace.unit_y = char(this.unit_y);
            %Old: this.Trace=MyTrace('filename','ScopeTrace','x',x,'y',y,...
                %'unit_x',char(this.unit_x),...
                %'unit_y',char(this.unit_y));
            %Triggers the event for acquired data
            triggerNewData(this);
        end
        
        function acquireContinuous(this)
            openDevice(this);
            fprintf(this.Device,...
                'ACQuire:STOPAfter RUNSTop;:ACQuire:STATE ON');
            %fprintf(this.Device, 'ACQuire:STATE ON');
            closeDevice(this);
        end
        
        function acquireSingle(this)
            openDevice(this);
            fprintf(this.Device,...
                'ACQuire:STOPAfter SEQuence;:ACQuire:STATE ON');
            %fprintf(this.Device, 'ACQuire:STATE ON');
            closeDevice(this);
        end
        
        function connectTCPIP(this)
            this.Device= visa('ni',...
                sprintf('TCPIP0::%s::inst0::INSTR',this.address));
            configureDefaultVisa(this);
        end
        
        function connectUSB(this)
            this.Device=visa('ni',sprintf('USB0::%s::INSTR',this.address));
            configureDefaultVisa(this);
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            addCommand(this,'channel','DATa:SOUrce','default',1,...
                'str_spec','CH%i');
            addCommand(this,'unit_x','WFMOutpre:XUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'unit_y','WFMOutpre:YUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'step_y','WFMOutpre:YMUlt','access','r',...
                'classes',{'numeric'});
            addCommand(this,'step_x','WFMOutpre:XINcr','access','r',...
                'classes',{'numeric'});
            addCommand(this,'x_zero','WFMOutpre:XZEro','access','r',...
                'classes',{'numeric'});
            addCommand(this,'y_data','CURVe','access','r',...
                'classes',{'numeric'});
            
            % numbers of points
            addCommand(this, 'point_no','HORizontal:RECOrdlength',...
                'default', 100000,...
                'val_list', {1000, 10000, 100000, 1000000, 10000000},...
                'str_spec','%i');
            % time scale in s per div
            addCommand(this, 'time_scale','HORizontal:SCAle',...
                'default',10E-3,...
                'str_spec','%e');
            
            % trigger level
            addCommand(this, 'trig_lev', 'TRIGger:A:LEVel',...
                'default',1,...
                'str_spec','%e');
            % trigger slope
            addCommand(this, 'trig_slope', 'TRIGger:A:EDGE:SLOpe',...
                'default', 'RISe', 'val_list',{'RISe','RIS','FALL'},...
                'str_spec','%s');
            % trigger source
            addCommand(this, 'trig_source', 'TRIGger:A:EDGE:SOUrce',...
                'default', 'AUX', 'val_list', {'CH1','CH2','CH3','CH4',...
                'EXT','LINE','AUX'},...
                'str_spec','%s');
            % trigger mode
            addCommand(this, 'trig_mode', 'TRIGger:A:MODe',...
                'default', 'AUTO', 'val_list',{'AUTO','NORMal','NORM'},...
                'str_spec','%s');
            % state of the data acquisition by the scope
            addCommand(this, 'acq_state', 'ACQuire:STATE',...
                'default',true, 'str_spec','%b')
            
            % Parametric commands
            for i = 1:4
                % coupling, AC, DC or GND
                i_str = num2str(i);
                addCommand(this,...
                    ['cpl',i_str],['CH',i_str,':COUP'],...
                    'default','DC', 'val_list', {'AC','DC','GND'},...
                    'str_spec','%s');              
                % impedances, 1MOhm or 50 Ohm
                addCommand(this,...
                    ['imp',i_str],['CH',i_str,':IMPedance'],...
                    'default','MEG', 'val_list', {'FIFty','FIF','MEG'},...
                    'str_spec','%s');
                % offset
                addCommand(this,...
                    ['offset',i_str],['CH',i_str,':OFFSet'],'default',0,...
                    'str_spec','%e');
                % scale, V/Div
                addCommand(this,...
                    ['scale',i_str],['CH',i_str,':SCAle'],'default',1,...
                    'str_spec','%e');
                % channel visible
            end
        end
    end
end