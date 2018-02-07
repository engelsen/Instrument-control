% Class for controlling 4-channel Agilent DSO scopes. 
% Tested with DSO7034A
classdef MyDso <MyInstrument
    properties (Constant=true)
        N_CHANNELS = 4; % number of channels
    end
    
    methods (Access=public)
        function this=MyDso(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
            connectDevice(this, interface, address);
            % 2e7 is the maximum trace size of DPO4034-3034 
            %(10 mln point of 2-byte integers)
            this.Device.InputBufferSize = 2.1e7; %byte 
            this.Trace.name_x='Time';
            this.Trace.name_y='Voltage';
        end
        
        function readTrace(this)
            %set data format to be signed integer, reversed byte order
            fprintf(this.Device,'WAVeform:BYTeorder LSBFirst');
            %2 bytes per measurement point
            fprintf(this.Device,'WAVeform:FORMat WORD');
            % read the trace
            fprintf(this.Device,'WAVeform:DATA?');
            y_data = int16(binblockread(this.Device,'int16'));
            
            % Reading the relevant parameters from the scope
            readProperty(this,...
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
            %this.Trace.unit_x = this.unit_x(2:end-1);
            %this.Trace.unit_y = this.unit_y(2:end-1);
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
        
        function turnKnob(this,knob,nturns)
            openDevice(this);
            %fprintf(this.Device, sprintf('FPAnel:TURN %s,%i',knob,nturns));
            closeDevice(this);
        end
    end
    
    methods (Access=private)
        function createCommandList(this)
            % channel from which the data is transferred
            addCommand(this,'channel','WAVeform:SOURce','default',1,...
                'str_spec','CHAN%i');
            %% currently selected in the scope display channel
            %addCommand(this, 'ctrl_channel', 'SELect:CONTROl',...
            %    'default',1, 'str_spec','CH%i');
            % scale for x and y waveform data
            addCommand(this,'step_y','WAVeform:YINCrement','access','r',...
                'classes',{'numeric'});
            addCommand(this,'step_x','WAVeform:XINCrement','access','r',...
                'classes',{'numeric'});
            addCommand(this,'x_zero','WAVeform:XORigin','access','r',...
                'classes',{'numeric'});           
            % numbers of points
            addCommand(this, 'point_no','WAVeform:POINts',...
                'default', 100000,...
                'val_list', {100, 250, 500, 1000, 2000, 5000, 10000,...
                20000, 50000, 100000, 200000, 500000, 1000000, 2000000,...
                4000000, 8000000},...
                'str_spec','%i');
            % time scale in s per div
            addCommand(this, 'time_scale','TIMebase:SCALe',...
                'default',10E-3,...
                'str_spec','%e');           
            % trigger level
            addCommand(this, 'trig_lev', 'TRIGger:LEVel',...
                'default',1,...
                'str_spec','%e');
            % trigger slope - works, but incompatible with Tektronix
            %addCommand(this, 'trig_slope', 'TRIGger:SLOpe',...
            %    'default', 'RISe', 'val_list',{'NEG','POS'},...
            %    'str_spec','%s');
            % trigger source
            addCommand(this, 'trig_source', 'TRIGger:SOUrce',...
                'default', 'AUX', 'val_list', {'CHAN1','CHAN2','CHAN3',...
                'CHAN4','EXT','LINE'},...
                'str_spec','%s');
            % trigger mode
            addCommand(this, 'trig_mode', 'TRIGger:SWEep',...
                'default', 'AUTO', 'val_list',{'AUTO','NORMal','NORM'},...
                'str_spec','%s');
            %% state of the data acquisition by the scope
            %addCommand(this, 'acq_state', 'ACQuire:STATE',...
            %    'default',true, 'str_spec','%b');
           
            % Parametric commands
            for i = 1:this.N_CHANNELS
                i_str = num2str(i);
                % coupling, AC, DC or GND
                addCommand(this,...
                    ['cpl',i_str],['CHANnel',i_str,':COUPling'],...
                    'default','DC', 'val_list', {'AC','DC','GND'},...
                    'str_spec','%s');              
                % impedances, 1MOhm or 50 Ohm works but incompatible with DPO
                %addCommand(this,...
                %    ['imp',i_str],['CHANnel',i_str,':IMPedance'],...
                %    'default','ONEMeg',...
                %    'val_list', {'FIFty','FIF','ONEMeg','ONEM'},...
                %    'str_spec','%s');
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