% Class for communication with NewFocus TLB6700 tunable laser controllers
% Needs UsbDllWrap.dll from Newport USB driver on Matlab path
%  
% Start instrument as MyTlb6700('address','USBaddr'), where USBaddr
% is indicated in the instrument menu. Example: MyTlb6700('address', '1').
%
% This class uses MyNewpUsbComm, an instance of which needs to be shared
% between multiple devices, as the Newport driver, apparently, cannot 
% handle concurrent calls.

classdef MyNewpTlb6700 < MyScpiInstrument & MyGuiCont
    
    properties (GetAccess = public, ...
            SetAccess = {?MyClassParser, ?MyTlb6700})
        
        % Interface field is not used in this instrument, but keep it
        % for the sake of information
        interface = 'usb'
        address = ''
    end
    
    properties (GetAccess = public, SetAccess = protected)
        
        % Instance of Newport.USBComm.USB used for communication. 
        % Must be shared between the devices
        UsbComm  
    end
    
    methods (Access = public)
        function this = MyNewpTlb6700(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            % Convert address to number
            this.address = str2double(this.address);
            
            % Get the unique instance of control class for Newport driver 
            this.UsbComm = MyNewpUsbComm.instance();
            
            createCommandList(this);
            
            this.gui_name = 'GuiNewpTlb';
        end
    end
    
    methods (Access = protected)  
        function createCommandList(this)
            
            % Commands for this class do not start from ':', as the
            % protocol does not fully comply with SCPI standard
            
            addCommand(this, 'wavelength', 'SENSe:WAVElength', ...
                'format',   '%e', ...
                'info',     'Output wavelength (nm)', ...
                'access',   'r');
            
            addCommand(this, 'current', 'SENSe:CURRent:DIODe', ...
                'format',   '%e', ...
                'info',     'Diode current (mA)', ...
                'access',   'r');

            addCommand(this, 'temp_diode', 'SENSe:TEMPerature:DIODe', ...
                'format',   '%e', ...
                'info',     'Diode temperature (C)', ...
                'access',   'r');

            addCommand(this, 'power', 'SENSe:POWer:DIODe', ...
                'format',   '%e', ...
                'info',     'Output power (mW)', ...
                'access',   'r');
            
            addCommand(this, 'wavelength_sp', 'SOURce:WAVElength', ...
                'format',   '%e', ...
                'info',     'Wavelength setpoint (nm)');

            addCommand(this, 'const_power', 'SOURce:CPOWer', ...
                'format',   '%b', ...
                'info',     'Constant power mode on/off');

            addCommand(this, 'power_sp', 'SOURce:POWer:DIODe', ...
                'format',   '%e', ...
                'info',     'Power setpoint (mW)');

            addCommand(this, 'current_sp', 'SOURce:CURRent:DIODe', ...
                'format',   '%e', ...
                'info',     'Current setpoint (mA)');
            
            % Control mode local/remote
            addCommand(this, 'control_mode', 'SYSTem:MCONtrol', ...
                'format',       '%s',...
                'info',         'Control local/remote', ...
                'value_list',   {'LOC','REM'});
            
            % Output on/off
            addCommand(this, 'enable_output', 'OUTPut:STATe', ...
                'format',   '%b', ...
                'info',     'on/off');
            
            % Wavelength track on/off
            addCommand(this, 'wavelength_track', 'OUTPut:TRACk', ...
                'format',   '%b', ...
                'info',     'on/off');
            
            % Wavelength scan related commands
            % Scan start wavelength (nm)
            addCommand(this, 'scan_start_wl', 'SOURce:WAVE:START', ...
                'format',   '%e', ...
                'info',     '(nm)');
            
            % Scan stop wavelength (nm)
            addCommand(this, 'scan_stop_wl', 'SOURce:WAVE:STOP', ...
                'format',   '%e', ...
                'info',     '(nm)');
            
            % Scan speed (nm/s)
            addCommand(this, 'scan_speed', 'SOURce:WAVE:SLEW:FORWard', ...
                'format',   '%e', ...
                'info',     '(nm/s)');
            
            % Maximum scan speed (nm/s)
            addCommand(this, 'scan_speed_max', 'SOURce:WAVE:MAXVEL', ...
                'format',   '%e', ...
                'info',     '(nm/s)', ...
                'access',   'r');
        end 
    end
    
    methods (Access = public)
        function openComm(this)
            
            % Opening a single device is not supported by Newport Usb 
            % Driver, so open all the devices of the given type
            stat = OpenDevices(this.UsbComm.Usb, hex2num('100A'));
            
            if ~stat
                warning('Could not open Newport TLB devices');
            end
        end
        
        % Query textual command
        function result = queryString(this, str)
            try
                result = query(this.UsbComm, this.address, str);
            catch ME
                try
                    % Attempt re-opening communication
                    openComm(this);
                    result = query(this.UsbComm, this.address, str);
                catch
                    rethrow(ME);
                end
            end
        end
        
        % Redefine queryStrings of MyScpiInstrument
        function res_list = queryStrings(this, varargin)
            if ~isempty(varargin)
                n_cmd = length(varargin);
                res_list = cell(n_cmd,1);
                
                % Query commands one by one as sending one query seems
                % to sometimes give errors if the string is very long
                for i = 1:n_cmd
                    cmd = [varargin{i},';'];
                    res_list{i} = queryString(this, cmd);
                end
            else
                res_list = {};
            end
        end
        
        % Writing is done by sending a command and querying its status.
        % Still, redefine writeStrings of MyScpiInstrument for consistency 
        % and clarity.
        function stat = writeString(this, str)
            stat = queryString(this, str);
        end
        
        function stat = writeStrings(this, varargin)
            stat = queryStrings(this, varargin{:});
        end
        
        %% Laser power and scan control functions
        
        function stat = setMaxOutPower(this)

            % Depending on if the laser in the constat power or current
            % mode, set value to max
            if this.const_power
                stat = queryString(this, 'SOURce:POWer:DIODe MAX;');
            else
                stat = queryString(this, 'SOURce:CURRent:DIODe MAX;');
            end
        end
        
        % Returns minimum and maximum wavelengths of the laser. There does 
        % not seem to be a more direct way of doing this with TLB6700 
        % other than setting and then reading the min/max values.
        function [wl_min, wl_max] = readMinMaxWavelength(this)
            tmp = this.scan_start_wl;
            
            % Read min wavelength of the laser
            writeStrings(this, 'SOURce:WAVE:START MIN');
            resp = queryStrings(this, 'SOURce:WAVE:START?');
            wl_min = str2double(resp{1});
            
            % Read max wavelength of the laser
            writeStrings(this, 'SOURce:WAVE:START MAX');
            resp = queryStrings(this, 'SOURce:WAVE:START?');
            wl_max = str2double(resp{1});
            
            % Return scan start to its original value
            this.scan_start_wl = tmp;
        end
        
        function configSingleScan(this)
            
            % Configure:
            % Do not switch the laser off during the backward scan,
            % Perform a signle scan,
            % Return at maximum speed
            writeStrings(this,'SOURce:WAVE:SCANCFG 0', ...
                'SOURce:WAVE:DESSCANS 1', ...
                'SOURce:WAVE:SLEW:RETurn MAX');
        end
        
        function startScan(this)
            writeStrings(this, 'OUTPut:SCAN:START');
        end
        
        function stopScan(this)
            writeStrings(this, 'OUTPut:SCAN:STOP');
        end
    end
end

