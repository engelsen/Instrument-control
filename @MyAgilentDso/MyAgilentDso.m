% Class for controlling 4-channel Agilent DSO scopes. 
% Tested with DSO7034A

classdef MyAgilentDso < MyScpiInstrument & MyDataSource & MyCommCont
    
    properties (Constant = true)
        channel_no = 4 % number of channels
    end
    
    methods (Access = public)
        function this = MyAgilentDso(varargin)
            this@MyCommCont(varargin{:});
            
            % 1.6e7 is the maximum trace size of DSO7034A 
            %(8 mln point of 2-byte integers)
            this.Comm.InputBufferSize = 2e7; %byte 
            this.Trace.name_x = 'Time';
            this.Trace.name_y = 'Voltage';
            this.Trace.unit_x = 's';
            this.Trace.unit_y = 'V';
            
            createCommandList(this);
        end
        
        function readTrace(this)
            this.Comm.ByteOrder = 'littleEndian';
            
            % Set data format to be signed integer, reversed byte order,
            % 2 bytes per measurement point, read the maximum
            % available number of points
            writeStrings(this, ...
                ':WAVeform:BYTeorder LSBFirst', ...
                ':WAVeform:FORMat WORD', ...
                ':WAVeform:POINts:MODE MAX', ...
                ':WAVeform:UNSigned OFF', ...
                ':WAVeform:DATA?');
            
            % Read the trace data
            y_data = int16(binblockread(this.Comm, 'int16'));  
            
            % Read the preamble
            pre_str = queryString(this, ':WAVeform:PREamble?');
            
            % Drop the end-of-the-string symbol and split
            pre = str2double(split(pre_str(1:end-1), ','));
            step_x = pre(5);
            step_y = pre(8);
            x_zero = pre(6);
            y_zero = pre(9);          
            
            % Calculate the y values
            y = double(y_data)*step_y + y_zero; 
            n_points = length(y);
            
            % Calculate the x axis
            x = linspace(x_zero, x_zero + step_x*(n_points-1), n_points);
            
            this.Trace.x = x;
            this.Trace.y = y;
            
            triggerNewData(this);
        end
        
        function acquireContinuous(this)
            writeString(this, ':RUN');
        end
        
        function acquireSingle(this)
            writeString(this, ':SINGLe');
        end
        
        function stopAcquisition(this)
            writeString(this, ':STOP');
        end
        
        % Emulates the physical knob turning, works with nturns=+-1
        function turnKnob(this, knob, nturns)
            switch upper(knob)
                case 'HORZSCALE'
                    
                    % Timebase is changed
                    if nturns == -1
                        this.time_scale = this.time_scale*2;
                    elseif nturns == 1
                        this.time_scale = this.time_scale/2;
                    else
                        return
                    end
                case {'VERTSCALE1', 'VERTSCALE2'}
                    
                    % Vertical scale is changed
                    n_ch = sscanf(upper(knob), 'VERTSCALE%i');
                    tag = sprintf('scale%i', n_ch);
                    if nturns==-1
                        this.(tag) = this.(tag)*2;
                    elseif nturns==1
                        this.(tag) = this.(tag)/2;
                    else
                        return
                    end
            end
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            addCommand(this, 'channel', ':WAVeform:SOURce', ...
                'format',   'CHAN%i', ...
                'info',     'Channel from which the data is transferred');
            
            addCommand(this, 'time_scale', ':TIMebase:SCALe',...
                'format',   '%e',...
                'info',     'Time scale (s/div)');           
            
            addCommand(this, 'trig_lev', ':TRIGger:LEVel', ...
                'format',   '%e');
            
            % trigger slope - works, but incompatible with Tektronix
            addCommand(this, 'trig_slope', ':TRIGger:SLOpe', ...
                'format',       '%s', ...
                'value_list',   {'NEGative', 'POSitive', 'EITHer', ...
                    'ALTernate'});
            
            addCommand(this, 'trig_source', ':TRIGger:SOUrce', ...
                'format',       '%s', ...
                'value_list',   {'CHAN1', 'CHAN2', 'CHAN3', 'CHAN4',...
                    'EXT','LINE'});
            
            % trigger mode
            addCommand(this, 'trig_mode', ':TRIGger:SWEep', ...
                'format',       '%s', ...
                'value_list',   {'AUTO', 'NORMal'});
            
            addCommand(this, 'acq_mode', ':ACQuire:TYPE', ...
                'format',       '%s', ...
                'info',         ['Acquisition mode: normal(sample), ', ...
                    'high resolution or average'], ...
                'value_list',   {'NORMal', 'AVERage', 'HRESolution', ...
                    'PEAK'});

            % Parametric commands
            for i = 1:this.channel_no
                i_str = num2str(i);
                
                addCommand(this, ...
                    ['cpl' i_str], [':CHANnel' i_str ':COUPling'], ...
                    'format',       '%s', ...
                    'info',         'Channel coupling: AC, DC or GND', ...
                    'value_list',   {'AC','DC','GND'});     
                
                addCommand(this, ...
                    ['imp' i_str], [':CHANnel' i_str ':IMPedance'], ...
                    'format',       '%s', ...
                    'info',         'Channel impedance: 1 MOhm or 50 Ohm', ...
                    'value_list',   {'FIFty','FIF','ONEMeg','ONEM'});
                
                addCommand(this,...
                    ['offset' i_str], [':CHANnel' i_str ':OFFSet'], ...
                    'format',   '%e', ...
                    'info',     '(V)');
                
                addCommand(this,...
                    ['scale' i_str], [':CHANnel' i_str ':SCAle'], ...
                    'format',   '%e', ...
                    'info',     'Channel y scale (V/div)');

                addCommand(this,...
                    ['enable' i_str], [':CHANnel' i_str ':DISPlay'], ...
                    'format',   '%b',...
                    'info',     'Channel enabled');
            end
        end
    end
end