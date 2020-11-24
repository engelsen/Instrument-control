% Class for communication with NewFocus TLB6300 tunable laser controllers

classdef MyNewpTlb6300 < MyScpiInstrument & MyCommCont & MyGuiCont
    
    methods (Access = public)
        function this = MyNewpTlb6300(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            connect(this);
            createCommandList(this);
            
            this.gui_name = 'GuiNewpTlb';
        end
        
        % Need to overwrite the standard query function as 
        % TLB6300 does not seem to support concatenation of commands 
        % in queries
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
            
            % Output wavelength, nm
            addCommand(this, 'wavelength',':SENS:WAVE',...
                'access','r','default',780,'format','%e',...
                'info','Output wavelength (nm)');
            % Diode current, mA
            addCommand(this, 'current',':SENS:CURR:DIOD',...
                'access','r','default',1,'format','%e',...
                'info','Diode current (mA)');
            % Diode temperature, C
            addCommand(this, 'temp_diode',':SENS:TEMP:LEV:DIOD',...
                'access','r','default',10,'format','%e',...
                'info','Diode temperature (C)');
            % Output power, mW
            addCommand(this, 'power',':SENS:POW:LEV:FRON',...
                'access','r','default',1,'format','%e',...
                'info','Output power (mW)');
            
            % Wavelength setpoint, nm
            addCommand(this, 'wavelength_sp',':WAVE',...
                'default',780,'format','%e',...
                'info','Wavelength setpoint (nm)');
            % Constant power mode on/off
            addCommand(this, 'const_power',':CPOW',...
                'access','w','default',true,'format','%b',...
                'info','Constant power mode on/off');
            % Power setpoint, mW
            addCommand(this, 'power_sp',':POW',...
                'access','w','default',10,'format','%e',...
                'info','Power setpoint (mW)');
            % Current setpoint, mW
            addCommand(this, 'current_sp',':CURR',...
                'default',100,'format','%e',...
                'info','Current setpoint (mA)');
            
            % Control mode local/remote
            addCommand(this, 'control_mode',':SYST:MCON',...
                'access','w','value_list',{'EXT','INT','LOC','REM'},...
                'default','LOC','format','%s',...
                'info','Control local(EXT)/remote(INT)');
            % Output on/off
            addCommand(this, 'enable_output',':OUTP',...
                'default',false,'format','%b',...
                'info','on/off');
            
            % Wavelength track is not fully remotely controllable with
            % TLB6300
        end
    end
    
    methods (Access = public)      
        function setMaxOutPower(this)
            
            % Depending on if the laser in the constat power or current
            % mode, set value to max
            if this.const_power
                
                % Actual power is clipped to max practical value 
                writeString(this, ':POW 99');
            else
                
                % Maximum current according to specs is 152 mA
                writeString(this, ':CURR 150');
            end
        end
    end
end

