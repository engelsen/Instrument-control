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
                'access','r','default',780,'fmt_spec','%e',...
                'info','Output wavelength (nm)');
            % Diode current, mA
            addCommand(this, 'current',':SENS:CURR:DIOD',...
                'access','r','default',1,'fmt_spec','%e',...
                'info','Diode current (mA)');
            % Diode temperature, C
            addCommand(this, 'temp_diode',':SENS:TEMP:LEV:DIOD',...
                'access','r','default',10,'fmt_spec','%e',...
                'info','Diode temperature (C)');
            % Output power, mW
            addCommand(this, 'power',':SENS:POW:LEV:FRON',...
                'access','r','default',1,'fmt_spec','%e',...
                'info','Output power (mW)');
            
            % Wavelength setpoint, nm
            addCommand(this, 'wavelength_sp',':WAVE',...
                'default',780,'fmt_spec','%e',...
                'info','Wavelength setpoint (nm)');
            % Constant power mode on/off
            addCommand(this, 'const_power',':CPOW',...
                'access','w','default',true,'fmt_spec','%b',...
                'info','Constant power mode on/off');
            % Power setpoint, mW
            addCommand(this, 'power_sp',':POW',...
                'access','w','default',10,'fmt_spec','%e',...
                'info','Power setpoint (mW)');
            % Current setpoint, mW
            addCommand(this, 'current_sp',':CURR',...
                'default',100,'fmt_spec','%e',...
                'info','Current setpoint (mA)');
            
            % Control mode local/remote
            addCommand(this, 'control_mode',':SYST:MCON',...
                'access','w','val_list',{'EXT','INT'},...
                'default','LOC','fmt_spec','%s',...
                'info','Control local(EXT)/remote(INT)');
            % Output on/off
            addCommand(this, 'enable_output',':OUTP',...
                'default',false,'fmt_spec','%b',...
                'info','on/off');
            
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
        
    end
end

