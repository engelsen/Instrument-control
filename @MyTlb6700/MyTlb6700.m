% Class for communication with NewFocus TLB6700 tunable laser controllers

classdef MyTlb6700 < MyScpiInstrument
    
    properties
        Property1
    end
    
    %% Constructor and destructor
    methods (Access=public)
        function this=MyTlb6700(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
        end
    end
    
    %% Private functions
    methods (Access=private)
        
        function createCommandList(this)
            % Output wavelength, nm
            addCommand(this, 'wavelength','SENSe:WAVElength',...
                'access','r','default',780,'str_spec','%e');
            % Diode current, mA
            addCommand(this, 'current','SENSe:CURRent:DIODe',...
                'access','r','default',1,'str_spec','%e');
            % Diode temperature, C
            addCommand(this, 'temp_diode','SENSe:TEMPerature:DIODe',...
                'access','r','default',10,'str_spec','%e');
            % Output power, mW
            addCommand(this, 'power','SENSe:POWer:DIODe',...
                'access','r','default',1,'str_spec','%e');
            
            % Wavelength setpoint, nm
            addCommand(this, 'wavelength_sp','SOURce:WAVElength',...
                'default',780,'str_spec','%e');
            % Constant power mode on/off
            addCommand(this, 'const_power','SOURce:CPOWer',...
                'default',true,'str_spec','%b');
            % Power setpoint, mW
            addCommand(this, 'power_sp','SOURce:POWer:DIODe',...
                'default',1,'str_spec','%e');
            
            % Control mode local/remote
            addCommand(this, 'control_mode','SYSTem:MCONtrol',...
                'val_list',{'LOC','REM'},...
                'default','LOC','str_spec','%s');
            % Output on/off
            addCommand(this, 'enable_output','OUTPut:STATe',...
                'default',false,'str_spec','%b');
            % Wavelength track on/off
            addCommand(this, 'wavelength_track','OUTPut:TRACk',...
                'default',true,'str_spec','%b');
        end
        
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        
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

