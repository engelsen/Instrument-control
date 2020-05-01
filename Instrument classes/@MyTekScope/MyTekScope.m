% Generic class for controlling Tektronix scopes

classdef MyTekScope < MyScpiInstrument & MyDataSource & MyCommCont ...
        & MyGuiCont
    
    properties (GetAccess = public, SetAccess={?MyClassParser,?MyTekScope})
        
        % number of channels
        channel_no = 4
        
        % List of the physical knobs, which can be rotated programmatically
        knob_list = {}
    end
    
    methods (Access = public)
        function this = MyTekScope(varargin)
            
            % Set default GUI name
            this.gui_name = 'GuiTekScope';
            
            this.Trace.name_x = 'Time';
            this.Trace.name_y = 'Voltage';
        end
        
        function readTrace(this)
            % Read units, offsets and steps for the scales
            % Moved the parm query before the data aquisition
            % because it seems that MSO has a problem responding
            % to query after data aquisition
            parms = queryStrings(this, ...
                ':WFMOutpre:XUNit?', ...
                ':WFMOutpre:YUNit?', ...
                ':WFMOutpre:XINcr?', ...
                ':WFMOutpre:YMUlt?', ...
                ':WFMOutpre:XZEro?', ...
                ':WFMOutpre:YZEro?', ...
                ':WFMOutpre:YOFf?');
            % Read raw y data
            y_data = readY(this);
           num_params = str2doubleHedged(parms);
           [unit_x, unit_y, step_x, step_y, x_zero, ...
               y_zero, y_offset] = num_params{:};
            
            % Calculating the y data
            y = (y_data-y_offset)*step_y+y_zero; 
            n_points = length(y);
            
            % Calculating the x data
            x = linspace(x_zero, x_zero + step_x*(n_points-1), n_points);
            
            this.Trace.x = x;
            this.Trace.y = y;
            
            % Discard "" when assiging the Trace labels
            this.Trace.unit_x = unit_x(2:end-1);
            this.Trace.unit_y = unit_y(2:end-1);
            
            triggerNewData(this);
        end
        
        function acquireContinuous(this)
            writeStrings(this, ...
                ':ACQuire:STOPAfter RUNSTop', ...
                ':ACQuire:STATE ON');
        end
        
        function acquireSingle(this)
            writeStrings(this, ...
                ':ACQuire:STOPAfter SEQuence', ...
                ':ACQuire:STATE ON');
        end
        
        function turnKnob(this, knob, nturns)
            writeString(this, sprintf(':FPAnel:TURN %s,%i', knob, nturns));
        end
    end
    
    methods (Access = protected)
        
        % The default version of this method works for DPO3034-4034 scopes
        function y_data = readY(this)
                
            % Configure data transfer: binary format and two bytes per 
            % point. Then query the trace. 
            this.Comm.ByteOrder = 'bigEndian';

            writeStrings(this, ...
                ':DATA:ENCDG RIBinary', ...
                ':DATA:WIDTH 2', ...
                ':DATA:STARt 1', ...
                sprintf(':DATA:STOP %i', this.point_no), ...
                ':CURVe?');

            y_data = double(binblockread(this.Comm, 'int16'));
            
            % read off the terminating character
            % which can not be read by the binblockread 
            if this.Comm.BytesAvailable == 1 || this.Comm.BytesAvailable == 2 
                fread(this.Comm,this.Comm.BytesAvailable,'uint8');
            end
            
            % For some reason MDO3000 scope needs to have an explicit pause 
            % between data reading and any other communication
            pause(0.01);
        end
    end
    
    methods
        function set.knob_list(this, val)
            assert(iscellstr(val), ['Value must be a cell array of ' ...
                'character strings.']) %#ok<ISCLSTR>
            this.knob_list = val;
        end
    end
end

