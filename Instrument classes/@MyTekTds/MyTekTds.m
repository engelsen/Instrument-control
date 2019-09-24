% Class for controlling 2-channel Tektronix TDS scopes. 

classdef MyTekTds < MyTekScope
    
    properties (Constant = true)
        point_no = 2500 % number of points is fixed for this device
    end
    
    methods (Access = public)
        function this = MyTekTds(varargin)
            P = MyClassParser(this);
            addParameter(P, 'enable_gui', false);
            processInputs(P, this, varargin{:});
            
            this.channel_no = 2;
            this.knob_list = lower({'HORZSCALE', 'VERTSCALE1', ...
                'VERTSCALE2'});
            
            connect(this);
            
            % 5e3 is the maximum trace size of TDS2022 
            %(2500 point of 2-byte integers)
            this.Comm.InputBufferSize = 1e4; % byte 
            
            createCommandList(this);
            
            if P.Results.enable_gui
                createGui(this);
            end
        end
        
        % Emulates the physical knob turning, works with nturns=+-1
        function turnKnob(this, knob, nturns)
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
            addCommand(this, 'channel', ':DATa:SOUrce', ...
                'format',       'CH%i', ...
                'info',         'Channel from which the data is transferred', ...
                'value_list',   {1, 2});
            
            addCommand(this, 'time_scale', ':HORizontal:MAIn:SCAle', ...
                'format',   '%e', ...
                'info',     'Time scale (s/div)');
            
            % Trigger level
            addCommand(this, 'trig_lev', ':TRIGger:MAIn:LEVel', ...
                'format',   '%e', ...
                'info',     '(V)');
            
            addCommand(this, 'trig_slope', ':TRIGger:MAIn:EDGE:SLOpe', ...
                'format',       '%s', ...
                'value_list',   {'RISe', 'FALL'});
            
            addCommand(this, 'trig_source', ':TRIGger:MAIn:EDGE:SOUrce',...
                'format',       '%s', ...
                'value_list',   {'CH1', 'CH2', 'EXT', 'EXT5', 'EXT10', ...
                    'AC LINE'});
            
            addCommand(this, 'trig_mode', ':TRIGger:MAIn:MODe', ...
                'format',       '%s', ...
                'value_list',   {'AUTO','NORMal'});
 
            addCommand(this, 'acq_state', ':ACQuire:STATE', ...
                'format',   '%b', ...
                'info',     'State of data acquisition by the scope');
           
            % Parametric commands
            for i = 1:this.channel_no
                i_str = num2str(i);
                
                addCommand(this,...
                    ['cpl',i_str], [':CH',i_str,':COUP'], ...
                    'format',       '%s', ...
                    'info',         'Channel coupling: AC, DC or GND', ...
                    'value_list',   {'DC', 'AC', 'GND'}); 
                
                addCommand(this,...
                    ['scale',i_str], [':CH',i_str,':SCAle'], ...
                    'format',   '%e',...
                    'info',     'Channel y scale (V/div)');
                
                addCommand(this,...
                    ['enable',i_str],[':SEL:CH',i_str], ...
                    'format',   '%b', ...
                    'info',     'Channel enabled');
            end
        end
    end
end