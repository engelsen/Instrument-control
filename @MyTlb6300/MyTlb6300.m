% Class for communication with NewFocus TLB6300 tunable laser controllers

classdef MyTlb6300 < MyScpiInstrument
    
    methods (Access=public)  
        % Need to overwrite the standard query function as 
        % TLB6300 does not seem to support concatenation of commands 
        % in queries
        function res_list=queryCommand(this, varargin)
            if ~isempty(varargin)
                % Send queries to the device one by one
                n_cmd = length(varargin);
                res_list = cell(n_cmd,1);
                for i=1:n_cmd
                    cmd=varargin{i};
                    res_list{i}=query(this.Device, cmd);
                end
            else
                res_list={};
            end
        end
    end
    %% Protected functions
    methods (Access=protected)  
        function createCommandList(this)
            % Output wavelength, nm
            addCommand(this, 'wavelength',':SENS:WAVE',...
                'access','r','default',780,'str_spec','%e');
            % Diode current, mA
            addCommand(this, 'current',':SENS:CURR:DIOD',...
                'access','r','default',1,'str_spec','%e');
            % Diode temperature, C
            addCommand(this, 'temp_diode',':SENS:TEMP:LEV:DIOD',...
                'access','r','default',10,'str_spec','%e');
            % Output power, mW
            addCommand(this, 'power',':SENS:POW:LEV:FRON',...
                'access','r','default',1,'str_spec','%e');
            
            % Wavelength setpoint, nm
            addCommand(this, 'wavelength_sp',':WAVE',...
                'default',780,'str_spec','%e');
            % Constant power mode on/off
            addCommand(this, 'const_power',':CPOW',...
                'access','w','default',true,'str_spec','%b');
            % Power setpoint, mW
            addCommand(this, 'power_sp',':POW',...
                'access','w','default',10,'str_spec','%e');
            % Current setpoint, mW
            addCommand(this, 'current_sp',':CURR',...
                'default',100,'str_spec','%e');
            
            % Control mode local/remote
            addCommand(this, 'control_mode',':SYST:MCON',...
                'access','w','val_list',{'EXT','INT'},...
                'default','LOC','str_spec','%s');
            % Output on/off
            addCommand(this, 'enable_output',':OUTP',...
                'default',false,'str_spec','%b');
            
            % Wavelength track is not fully remotely controllable with
            % TLB6300
        end
        
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        
        function setMaxOutPower(this)
            % Depending on if the laser in the constat power or current
            % mode, set value to max
            openDevice(this);
            if this.const_power
                % Actual power is clipped to max practical value 
                writeCommand(this, ':POW 99');
            else
                % Maximum current according to specs is 152 mA
                writeCommand(this, ':CURR 150');
            end
            closeDevice(this);
        end
        
        function scanSingle(this, start_wl, stop_wl, speed)
            % Do not switch the laser off during the backward scan
            fprintf(this.Device,'SOURce:WAVE:SCANCFG 1;');
            % single scan
            fprintf(this.Device,'SOURce:WAVE:DESSCANS 1;');
            % Set start and stop wavelengths
            fprintf(this.Device,'SOURce:WAVE:START %e',start_wl);
            fprintf(this.Device,'SOURce:WAVE:STOP %e',stop_wl);
            fprintf(this.Device,'SOURce:WAVE:SLEW:FORWard %e',speed);
            % Return at maximum speed 
            fprintf(this.Device,'SOURce:WAVE:SLEW:RETurn MAX');
            
            % Start scan
            fprintf(this.Device,'OUTPut:SCAN:START');
        end
    end
end

