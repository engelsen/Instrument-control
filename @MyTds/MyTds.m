% Class for controlling 2-channel Tektronix TDS scopes. 

classdef MyTds < MyTekScope
    
    properties (Constant = true)
        point_no = 2500 % number of points is fixed for this device
    end
    
    methods (Access = public)
        function this = MyTds(varargin)
            this@MyTekScope(varargin{:});
            
            this.channel_no = 2;
            this.knob_list = lower({'HORZSCALE', 'VERTSCALE1', ...
                'VERTSCALE2'});
            
            % 5e3 is the maximum trace size of TDS2022 
            %(2500 point of 2-byte integers)
            this.Comm.InputBufferSize = 1e4; %byte 
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
                    
                    writeString(this, ...
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
                    
                    writeString(this, sprintf('CH%i:SCAle %i',n_ch,sc));
            end
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % channel from which the data is transferred
            addCommand(this,'channel',':DATa:SOUrce','default',1,...
                'format','CH%i',...
                'info','Channel from which the data is transferred');
            
            % time scale in s per div
            addCommand(this, 'time_scale',':HORizontal:MAIn:SCAle',...
                'default',10E-3,...
                'format','%e',...
                'info','Time scale (s/division)');
            
            % trigger level
            addCommand(this, 'trig_lev', ':TRIGger:MAIn:LEVel',...
                'default',1,...
                'format','%e');
            
            % trigger slope
            addCommand(this, 'trig_slope', ':TRIGger:MAIn:EDGE:SLOpe',...
                'default', 'RISe', 'val_list',{'RISe','RIS','FALL'},...
                'format','%s');
            
            % trigger source
            addCommand(this, 'trig_source', ':TRIGger:MAIn:EDGE:SOUrce',...
                'default', 'AUX', 'val_list', {'CH1','CH2',...
                'EXT','EXT5','EXT10','AC LINE'}, 'format','%s');
            
            % trigger mode
            addCommand(this, 'trig_mode', ':TRIGger:MAIn:MODe',...
                'default', 'AUTO', 'val_list',{'AUTO','NORMal','NORM'},...
                'format','%s');
            % state of the data acquisition by the scope
            addCommand(this, 'acq_state', ':ACQuire:STATE',...
                'default',true, 'format','%b',...
                'info','State of data acquisition by the scope');
           
            % Parametric commands
            for i = 1:this.N_CHANNELS
                i_str = num2str(i);
                % coupling, AC, DC or GND
                addCommand(this,...
                    ['cpl',i_str],[':CH',i_str,':COUP'],...
                    'default','DC', 'val_list', {'AC','DC','GND'},...
                    'format','%s',...
                    'info','Channel coupling: AC, DC or GND');              
                % scale, V/Div
                addCommand(this,...
                    ['scale',i_str],[':CH',i_str,':SCAle'],'default',1,...
                    'format','%e',...
                    'info','Channel y scale (V/division)');
                % channel enabled
                addCommand(this,...
                    ['enable',i_str],[':SEL:CH',i_str],'default',true,...
                    'format','%b',...
                    'info','Channel enabled');
            end
        end
    end
end