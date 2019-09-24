% Class for Thorlabs PM100D powermeters 

classdef MyThorlabsPm < MyScpiInstrument & MyCommCont & MyGuiCont
 
    methods (Access = public)
        function this = MyThorlabsPm(varargin)
            P = MyClassParser(this);
            addParameter(P, 'enable_gui', false);
            processInputs(P, this, varargin{:});
            
            connect(this);
            
            % reading from powermeter is quick
            this.Comm.Timeout = 1; 
            
            createCommandList(this);
            
            if P.Results.enable_gui
                createGui(this);
            end
        end

        % Appantly, this device sometimemes fails if it receives very long 
        % commands, so query them one by one         
        function writeStrings(this, varargin)
            
            % Send commands to device one by one
            for i=1:length(varargin)
                cmd_str = varargin{i};
                writeString(this, cmd_str);
            end
        end
        
        % Query commands and return resut as cell array of strings
        function res_list = queryStrings(this, varargin)
            
            % Send commands to device one by one
            ncmd = length(varargin);
            res_list = cell(1,ncmd);
            
            for i = 1:ncmd
                cmd_str = varargin{i};
                res_list{i} = queryString(this, cmd_str);
            end
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % Sensor name and info
            addCommand(this, 'sensor', ':SYSTem:SENSor:IDN', ...
                'format',   '%s', ...
                'access',   'r');
            
            addCommand(this, 'average_no',':SENSe:AVERage:COUNt', ...
                'format',   '%i', ...
                'info',     ['Number of averages, 1 sample takes ' ...
                    'approx. 3ms']);
            
            addCommand(this, 'wl', ':SENSe:CORRection:WAVelength',...
                'format',   '%e', ...
                'info',     'Operation wavelength (nm)');
            
            addCommand(this, 'auto_pow_rng', ...
                ':SENSe:POWer:DC:RANGe:AUTO', ...
                'format',   '%b', ...
                'info',     'Auto power range');
            
            addCommand(this, 'power_unit', ':SENSe:POWer:DC:UNIT', ...
                'format',       '%s',...
                'value_list',   {'W', 'DBM'})
            
            addCommand(this, 'power', ':MEASure:POWer', ...
                'format',   '%e', ...
                'access',   'r')
        end
    end
end
