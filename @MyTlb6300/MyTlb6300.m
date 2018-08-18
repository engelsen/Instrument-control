% Class for communication with NewFocus TLB6300 tunable laser controllers

classdef MyTlb6300 < MyScpiInstrument
    
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
                'access','w','default',1,'str_spec','%e');
            
            % Control mode local/remote
            addCommand(this, 'control_mode',':SYST:MCON',...
                'access','w','val_list',{'INT','EXT'},...
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
        
        function stat = setMaxOutPower(this)
            % Depending on if the laser in the constat power or current
            % mode, set value to max
            if this.const_power
                Query(this.Device, this.address, ...
                    'SOURce:CURRent:DIODe MAX;', this.QueryData);
            else
                Query(this.Device, this.address, ...
                    'SOURce:POWer:DIODe MAX;', this.QueryData);
            end
            stat = char(ToString(this.QueryData));
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

