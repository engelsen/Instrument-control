% Class for controlling 4-channel Agilent DSO scopes. 
% Tested with DSO7034A
classdef MyDso <MyInstrument
    properties (SetAccess=protected, GetAccess=public)
        % properties, read a a preamble during the trace reading
        step_x;
        step_y;
        x_zero;
        y_zero;
        point_no;
    end
    properties (Constant=true)
        N_CHANNELS = 4; % number of channels
    end
    
    methods (Access=public)
        function this=MyDso(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
            connectDevice(this, interface, address);
            % 1.6e7 is the maximum trace size of DSO7034A 
            %(8 mln point of 2-byte integers)
            this.Device.InputBufferSize = 2e7; %byte 
            this.Trace.name_x='Time';
            this.Trace.name_y='Voltage';
            this.Trace.unit_x = 's';
            this.Trace.unit_y = 'V';
        end
        
        function readTrace(this)
            % set data format to be signed integer, reversed byte order,
            % 2 bytes per measurement point, and also read the maximun
            % avaliable number of points
            fprintf(this.Device,['WAVeform:BYTeorder MSBFirst;',...
                ':WAVeform:FORMat WORD;:WAVeform:POINts:MODE MAX']);
            % read preamble
            pre_str = query(this.Device, 'WAVeform:PREamble?');
            % drop the end-of-the-string symbol and split
            pre = str2double(split(pre_str(1:end-1),','));
            this.point_no = pre(3);
            this.step_x = pre(5);
            this.step_y = pre(8);
            this.x_zero = pre(6);
            this.y_zero = pre(9);
            % read the trace
            fprintf(this.Device,'WAVeform:DATA?');
            y_data = int16(binblockread(this.Device,'int16'));            
            % Calculating the y data
            y = double(y_data)*this.step_y + this.y_zero; 
            n_points=length(y);
            % Calculating the x axis
            x = linspace(this.x_zero,...
                this.x_zero+this.step_x*(n_points-1),n_points);
            this.Trace.x = x;
            this.Trace.y = y;
            triggerNewData(this);
        end
        
        function acquireContinuous(this)
            openDevice(this);
            fprintf(this.Device,'RUN');
            closeDevice(this);
        end
        
        function acquireSingle(this)
            openDevice(this);
            fprintf(this.Device,'SINGLe');
            closeDevice(this);
        end
        
        function stopAcquisition(this)
            openDevice(this);
            fprintf(this.Device,'STOP');
            closeDevice(this);
        end
        
        % Emulates the physical knob turning, works with nturns=+-1
        function turnKnob(this,knob,nturns)
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
                    writePropertyHedged(this, 'time_scale', sc);
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
                    writePropertyHedged(this, sprintf('scale%i',n_ch), sc);
            end
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            % channel from which the data is transferred
            addCommand(this,'channel','WAVeform:SOURce','default',1,...
                'str_spec','CHAN%i');
            % time scale in s per div
            addCommand(this, 'time_scale','TIMebase:SCALe',...
                'default',10E-3,...
                'str_spec','%e');           
            % trigger level
            addCommand(this, 'trig_lev', 'TRIGger:LEVel',...
                'default',1,...
                'str_spec','%e');
            % trigger slope - works, but incompatible with Tektronix
            addCommand(this, 'trig_slope', 'TRIGger:SLOpe',...
                'default', 'RISe', 'val_list',{'NEG','POS','EITH','ALT',... 
                'NEGative','POSitive','EITHer','ALTernate'},...
                'str_spec','%s');
            % trigger source
            addCommand(this, 'trig_source', 'TRIGger:SOUrce',...
                'default', 'AUX', 'val_list', {'CHAN1','CHAN2','CHAN3',...
                'CHAN4','EXT','LINE'},...
                'str_spec','%s');
            % trigger mode
            addCommand(this, 'trig_mode', 'TRIGger:SWEep',...
                'default', 'AUTO', 'val_list',{'AUTO','NORMal','NORM'},...
                'str_spec','%s');
           
            % Parametric commands
            for i = 1:this.N_CHANNELS
                i_str = num2str(i);
                % coupling, AC, DC or GND
                addCommand(this,...
                    ['cpl',i_str],['CHANnel',i_str,':COUPling'],...
                    'default','DC', 'val_list', {'AC','DC','GND'},...
                    'str_spec','%s');              
                % impedances, 1MOhm or 50 Ohm works but incompatible with DPO
                addCommand(this,...
                    ['imp',i_str],['CHANnel',i_str,':IMPedance'],...
                    'default','ONEMeg',...
                    'val_list', {'FIFty','FIF','ONEMeg','ONEM'},...
                    'str_spec','%s');
                % offset
                addCommand(this,...
                    ['offset',i_str],['CHANnel',i_str,':OFFSet'],'default',0,...
                    'str_spec','%e');
                % scale, V/Div
                addCommand(this,...
                    ['scale',i_str],['CHANnel',i_str,':SCAle'],'default',1,...
                    'str_spec','%e');
                % channel enabled
                addCommand(this,...
                    ['enable',i_str],['CHANnel',i_str,':DISPlay'],'default',true,...
                    'str_spec','%b');
            end
        end
    end
end