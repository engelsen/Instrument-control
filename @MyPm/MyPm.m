% Class for Thorlabs PM100D powermeters 
classdef MyPm < MyScpiInstrument
    %% Constructor and destructor
    methods (Access=public)
        function this=MyPm(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            this.Device.Timeout=1; % reading from powermeter is quick
        end
        
        %% Low-level functions for reading and writing textual data to the device
        % Appantly, this device sometimemes fails if it receives very long 
        % commands, so query them one by one 
        
        function writeCommand(this, varargin)
            % Send commands to device one by one
            for i=1:length(varargin)
                cmd_str=varargin{i};
                fprintf(this.Device, cmd_str);
            end
        end
        
        % Query commands and return resut as cell array of strings
        function res_list=queryCommand(this, varargin)
            % Send commands to device one by one
            ncmd=length(varargin);
            res_list=cell(1,ncmd);
            for i=1:ncmd
                cmd_str=varargin{i};
                res_list{i}=query(this.Device, cmd_str);
            end
        end
    end
    
    %% Protected functions
    methods (Access=protected)
        
        function createCommandList(this)
            % Sensor name and info
            addCommand(this, 'sensor',':SYSTem:SENSor:IDN',...
                'fmt_spec','%s',...
                'default','',...
                'access','r');
            addCommand(this, 'average_no',':SENSe:AVERage:COUNt',...
                'fmt_spec','%i',...
                'default',1,...
                'info','Number of averages, 1 sample takes approx. 3ms');
            addCommand(this, 'wl', ':SENSe:CORRection:WAVelength',...
                'fmt_spec','%e',...
                'default',700,...
                'info','Operation wavelength (nm)')
            addCommand(this, 'auto_pow_rng', ':SENSe:POWer:DC:RANGe:AUTO',...
                'fmt_spec','%b',...
                'default',true,...
                'info','Auto power range')
            addCommand(this, 'power_unit', ':SENSe:POWer:DC:UNIT',...
                'fmt_spec','%s',...
                'default','W',...
                'val_list',{'W', 'DBM'})
            addCommand(this, 'power', ':MEASure:POWer',...
                'default',0,...
                'fmt_spec','%e','access','r')
        end
        
    end
end
