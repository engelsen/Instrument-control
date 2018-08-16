% Class for controlling 2-channel Tektronix TDS scopes. 
classdef MyTds <MyScpiInstrument
    properties (Constant=true)
        N_CHANNELS = 2; % number of channels
        POINT_NO = 2500; % number of points is fixed for this device
    end
    
    methods (Access=public)
        function this=MyTds(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});

            % 5e3 is the maximum trace size of TDS2022 
            %(2500 point of 2-byte integers)
            this.Device.InputBufferSize = 1e4; %byte 
            this.Trace.name_x='Time';
            this.Trace.name_y='Voltage';
        end
        
        function readTrace(this)
            %set data format to be signed integer, reversed byte order
            fprintf(this.Device,'DATA:ENCDG SRIbinary');
            %2 bytes per measurement point
            fprintf(this.Device,'DATA:WIDTH 2');
            % read the entire trace
            fprintf(this.Device,'DATA:START 1;STOP %i;',this.POINT_NO);
            fprintf(this.Device,'CURVE?');
            y_data = int16(binblockread(this.Device,'int16'));
            
            % Reading the relevant parameters from the scope
            readProperty(this,'unit_y','unit_x',...
                'step_x','step_y','x_zero');
                        
            % Calculating the y data
            y = double(y_data)*this.step_y; 
            n_points=length(y);
            % Calculating the x axis
            x = linspace(this.x_zero,...
                this.x_zero+this.step_x*(n_points-1),n_points);
            
            this.Trace.x = x;
            this.Trace.y = y;
            % Discard "" when assiging the Trace labels
            this.Trace.unit_x = this.unit_x(2:end-1);
            this.Trace.unit_y = this.unit_y(2:end-1);
            triggerNewData(this);
        end
        
        function acquireContinuous(this)
            openDevice(this);
            fprintf(this.Device,...
                'ACQuire:STOPAfter RUNSTop;:ACQuire:STATE ON');
            closeDevice(this);
        end
        
        function acquireSingle(this)
            openDevice(this);
            fprintf(this.Device,...
                'ACQuire:STOPAfter SEQuence;:ACQuire:STATE ON');
            closeDevice(this);
        end
        
        % Emulates the physical knob turning, works with nturns=+-1
        function turnKnob(this,knob,nturns)
            openDevice(this);
            switch upper(knob)
                case 'HORZSCALE'
                    % timebase is changed
                    if nturns==-1
                        sc = this.time_scale*2;
                    elseif nturns==1
                        sc = this.time_scale/2;
                    else
                        return
                    end
                    fprintf(this.Device,...
                        sprintf('HORizontal:MAIn:SCAle %i',sc));
                case {'VERTSCALE1', 'VERTSCALE2'}
                    % vertical scale is changed
                    n_ch = sscanf(upper(knob), 'VERTSCALE%i');
                    tag = sprintf('scale%i', n_ch);
                    if nturns==-1
                        sc = this.(tag)*2;
                    elseif nturns==1
                        sc = this.(tag)/2;
                    else
                        return
                    end
                    fprintf(this.Device, sprintf('CH%i:SCAle %i',n_ch,sc));
            end
            closeDevice(this);
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            % channel from which the data is transferred
            addCommand(this,'channel','DATa:SOUrce','default',1,...
                'str_spec','CH%i');
            % units and scale for x and y waveform data
            addCommand(this,'unit_x','WFMPre:XUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'unit_y','WFMPre:YUNit','access','r',...
                'classes',{'char'});
            addCommand(this,'step_y','WFMPre:YMUlt','access','r',...
                'classes',{'numeric'});
            addCommand(this,'step_x','WFMPre:XINcr','access','r',...
                'classes',{'numeric'});
            addCommand(this,'x_zero','WFMPre:XZEro','access','r',...
                'classes',{'numeric'});           
            % time scale in s per div
            addCommand(this, 'time_scale','HORizontal:MAIn:SCAle',...
                'default',10E-3,...
                'str_spec','%e');           
            % trigger level
            addCommand(this, 'trig_lev', 'TRIGger:MAIn:LEVel',...
                'default',1,...
                'str_spec','%e');
            % trigger slope
            addCommand(this, 'trig_slope', 'TRIGger:MAIn:EDGE:SLOpe',...
                'default', 'RISe', 'val_list',{'RISe','RIS','FALL'},...
                'str_spec','%s');
            % trigger source
            addCommand(this, 'trig_source', 'TRIGger:MAIn:EDGE:SOUrce',...
                'default', 'AUX', 'val_list', {'CH1','CH2',...
                'EXT','EXT5','EXT10','AC LINE'}, 'str_spec','%s');
            % trigger mode
            addCommand(this, 'trig_mode', 'TRIGger:MAIn:MODe',...
                'default', 'AUTO', 'val_list',{'AUTO','NORMal','NORM'},...
                'str_spec','%s');
            % state of the data acquisition by the scope
            addCommand(this, 'acq_state', 'ACQuire:STATE',...
                'default',true, 'str_spec','%b');
           
            % Parametric commands
            for i = 1:this.N_CHANNELS
                i_str = num2str(i);
                % coupling, AC, DC or GND
                addCommand(this,...
                    ['cpl',i_str],['CH',i_str,':COUP'],...
                    'default','DC', 'val_list', {'AC','DC','GND'},...
                    'str_spec','%s');              
                % scale, V/Div
                addCommand(this,...
                    ['scale',i_str],['CH',i_str,':SCAle'],'default',1,...
                    'str_spec','%e');
                % channel enabled
                addCommand(this,...
                    ['enable',i_str],['SEL:CH',i_str],'default',true,...
                    'str_spec','%b');
            end
        end
    end
end