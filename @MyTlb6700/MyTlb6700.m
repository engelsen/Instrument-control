% Class for communication with NewFocus TLB6700 tunable laser controllers
% Needs UsbDllWrap.dll from Newport USB driver on Matlab path
% Address field is ignored for this class. 
% Start instrument as MyTlb6700('','USBaddr'), where USBaddr is indicated
% in the instrument menu. Example: MyTlb6700('','1')
%
% This class does not have 'Device' property but uses the communication
% class UsbComm (which needs to be shared between multiple devices) to
% mimic some of the standard MyInstrument operations.
%
% Operation of opening devices is time-consuming with Newport USB driver,
% on the other hand multiple open devices do not interfere. So keep 
% the device open for the whole session

classdef MyTlb6700 < MyScpiInstrument
    
    properties (SetAccess=protected, GetAccess=public)
        % Instance of Newport.USBComm.USB used for communication. 
        % Must be shared between the devices
        UsbComm  
    end
    
    %% Constructor and destructor
    methods (Access=public)
        
        function this=MyTlb6700(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            % Interface field is not used in this instrument, but is
            % assigned value for the purpose of information
            this.interface='usb';
            % Convert address to number
            this.address=str2double(this.address);
        end
        
    end
    
    %% Protected functions
    methods (Access=protected)  
        function createCommandList(this)
            % Commands for this class do not start from ':', as the
            % protocol does not fully comply with SCPI standard
            
            % Output wavelength, nm
            addCommand(this, 'wavelength','SENSe:WAVElength',...
                'access','r','default',780,'fmt_spec','%e',...
                'info','Output wavelength (nm)');
            % Diode current, mA
            addCommand(this, 'current','SENSe:CURRent:DIODe',...
                'access','r','default',1,'fmt_spec','%e',...
                'info','Diode current (mA)');
            % Diode temperature, C
            addCommand(this, 'temp_diode','SENSe:TEMPerature:DIODe',...
                'access','r','default',10,'fmt_spec','%e',...
                'info','Diode temperature (C)');
            % Output power, mW
            addCommand(this, 'power','SENSe:POWer:DIODe',...
                'access','r','default',1,'fmt_spec','%e',...
                'info','Output power (mW)');
            
            % Wavelength setpoint, nm
            addCommand(this, 'wavelength_sp','SOURce:WAVElength',...
                'default',780,'fmt_spec','%e',...
                'info','Wavelength setpoint (nm)');
            % Constant power mode on/off
            addCommand(this, 'const_power','SOURce:CPOWer',...
                'default',true,'fmt_spec','%b',...
                'info','Constant power mode on/off');
            % Power setpoint, mW
            addCommand(this, 'power_sp','SOURce:POWer:DIODe',...
                'default',10,'fmt_spec','%e',...
                'info','Power setpoint (mW)');
            % Current setpoint, mA
            addCommand(this, 'current_sp','SOURce:CURRent:DIODe',...
                'default',100,'fmt_spec','%e',...
                'info','Current setpoint (mA)');
            
            % Control mode local/remote
            addCommand(this, 'control_mode','SYSTem:MCONtrol',...
                'val_list',{'LOC','REM'},...
                'default','LOC','fmt_spec','%s',...
                'info','Control local/remote');
            % Output on/off
            addCommand(this, 'enable_output','OUTPut:STATe',...
                'default',false,'fmt_spec','%b',...
                'info','on/off');
            % Wavelength track on/off
            addCommand(this, 'wavelength_track','OUTPut:TRACk',...
                'default',true,'fmt_spec','%b',...
                'info','on/off');
            
            % Wavelength scan related commands
            % Scan start wavelength (nm)
            addCommand(this, 'scan_start_wl','SOURce:WAVE:START',...
                'default',0,'fmt_spec','%e',...
                'info','(nm)');
            % Scan stop wavelength (nm)
            addCommand(this, 'scan_stop_wl','SOURce:WAVE:STOP',...
                'default',0,'fmt_spec','%e',...
                'info','(nm)');
            % Scan speed (nm/s)
            addCommand(this, 'scan_speed','SOURce:WAVE:SLEW:FORWard',...
                'default',0,'fmt_spec','%e',...
                'info','(nm/s)');
            % Maximum scan speed (nm/s)
            addCommand(this, 'scan_speed_max','SOURce:WAVE:MAXVEL',...
                'access','r','default',0,'fmt_spec','%e',...
                'info','(nm/s)');
        end
        
    end
    
    %% Public functions including callbacks
    methods (Access=public)
        % NewFocus lasers no not support visa communication, thus need to
        % overload connectDevice, writeCommand and queryCommand methods
        function connectDevice(this)
            % In this case 'interface' property is ignored and 'address' is
            % the USB address, indicated in the controller menu
            
            % Get the unique instance of control class for Newport driver 
            this.UsbComm=MyNewportUsbComm.instance();
            
        end
         
        function openDevice(this)
            OpenDevices(this.UsbComm.Usb, hex2num('100A'));
        end
        
        % Overload isopen method of MyInstrument
        function bool=isopen(this)
            % Could not find a better way to check if device is open other
            % than attempting communication with it
            try
                str=query(this.UsbComm, this.address, '*IDN?');
                if ~isempty(str)
                    bool=true;
                end
            catch
                bool=false;
            end
        end
        
        function closeDevice(this)
            disp(['A single device cannot be closed with Newport Usb Driver'])
            % CloseDevices(this.UsbComm.Usb);
        end
        
        function stat_list=writeCommand(this, varargin)
            % Create auxiliary variable for device communication
            % Query is used for writing as the controller always returns
            % a status string that needs to be read out
            if ~isempty(varargin)
                n_cmd=length(varargin);
                stat_list=cell(n_cmd,1);
                % Send commands one by one as sending one query seems
                % to sometimes give errors if the string is very long
                for i=1:n_cmd
                    cmd = [varargin{i},';'];
                    stat_list{i} = query(this.UsbComm, this.address, cmd);
                end
            end
        end
        
        function res_list=queryCommand(this, varargin)
            if ~isempty(varargin)
                n_cmd=length(varargin);
                res_list=cell(n_cmd,1);
                % Query commands one by one as sending one query seems
                % to sometimes give errors if the string is very long
                for i=1:n_cmd
                    cmd = [varargin{i},';'];
                    res_list{i} = query(this.UsbComm, this.address, cmd);
                end
            else
                res_list={};
            end
        end
        
        % readPropertyHedged and writePropertyHedged
        % are overloaded to not close the device
        function writePropertyHedged(this, varargin)
            openDevice(this);
            try
                writeProperty(this, varargin{:});
            catch
                warning('Error while writing the properties:');
                disp(varargin);
            end
            readProperty(this, 'all');
        end
        
        function result=readPropertyHedged(this, varargin)
            openDevice(this);
            try
                result = readProperty(this, varargin{:});
            catch
                warning('Error while reading the properties:');
                disp(varargin);
            end
        end
        
        % Attempt communication and identification
        function [str, msg]=idn(this)
            try
                openDevice(this);
                str=query(this.UsbComm, this.address, '*IDN?');
                if isempty(str)
                    msg='Communication with controller failed';
                else
                    msg='';
                end
            catch ErrorMessage
                str='';
                msg=ErrorMessage.message;
            end
            this.idn_str=str;
        end
        
        function stat = setMaxOutPower(this)
            openDevice(this);
            % Depending on if the laser in the constat power or current
            % mode, set value to max
            if this.const_power
                stat = query(this.UsbComm, this.address, ...
                    'SOURce:POWer:DIODe MAX;');
            else
                stat = query(this.UsbComm, this.address, ...
                    'SOURce:CURRent:DIODe MAX;');
            end
        end
        
        % Returns minimum and maximum wavelengths of the laser. There does 
        % not seem to be a more direct way of doing this with TLB6700 
        % other than setting and then reading the min/max values.
        function [wl_min, wl_max] = readMinMaxWavelength(this)
            tmp=this.scan_start_wl;
            openDevice(this);
            % Read min wavelength of the laser
            writeCommand(this, 'SOURce:WAVE:START MIN');
            resp=queryCommand(this, 'SOURce:WAVE:START?');
            wl_min=str2double(resp{1});
            % Read max wavelength of the laser
            writeCommand(this, 'SOURce:WAVE:START MAX');
            resp=queryCommand(this, 'SOURce:WAVE:START?');
            wl_max=str2double(resp{1});
            % Return scan start to its original value
            writeProperty(this, 'scan_start_wl', tmp);
        end
        
        %% Wavelength scan-related functions
        function configSingleScan(this)
            openDevice(this);
            % Configure:
            % Do not switch the laser off during the backward scan,
            % Perform a signle scan,
            % Return at maximum speed
            writeCommand(this,'SOURce:WAVE:SCANCFG 0',...
                'SOURce:WAVE:DESSCANS 1',...
                'SOURce:WAVE:SLEW:RETurn MAX');
        end
        
        function startScan(this)
            openDevice(this);
            writeCommand(this,'OUTPut:SCAN:START');
        end
        
        function stopScan(this)
            openDevice(this);
            writeCommand(this,'OUTPut:SCAN:STOP');
        end
    end
end

