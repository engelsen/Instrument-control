% Class for communication with NewFocus TLB6700 tunable laser controllers
% Needs UsbDllWrap.dll from Newport USB driver on Matlab path

classdef MyTlb6700 < MyScpiInstrument
    
    properties (SetAccess=protected, GetAccess=public)
        NetAsm; % .NET assembly
        QueryData; % auxiliary variable for device communication
    end
    
    %% Constructor and destructor
    methods (Access=public)
        function this=MyTlb6700(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            
            this.QueryData=System.Text.StringBuilder(64);
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
        % NewFocus lasers no not support visa communication, thus need to
        % overload connectDevice, writeCommand and queryCommand methods
        function connectDevice(this)
            % In this case 'interface' property is ignored and 'address' is
            % the device key
            dll_path = which('UsbDllWrap.dll');
            if isempty(dll_path)
                error(['UsbDllWrap.dll is not found. This library ',...
                    'is a part of Newport USB driver and needs ',...
                    'to be present on Matlab path.'])
            end
            this.NetAsm=NET.addAssembly(dll_path);
            % Create an instance of Newport.USBComm.USB class
            Type=GetType(this.NetAsm.AssemblyHandle,'Newport.USBComm.USB');
            this.Device=System.Activator.CreateInstance(Type);
            
            % Operation of opening device is time-consuming in this case,
            % on the other hand multiple open devices do not interfere. So
            % keep the device open for the whole session;
            openDevice(this);
        end
         
        function openDevice(this)
            % '100A' is a code, corresponding to TLB6700 laser controller
            OpenDevices(this.Device, hex2num('100A'));
        end
        
        function closeDevice(this)
            CloseDevices(this.Device);
        end
        
        function stat_list=writeCommand(this, varargin)
            if ~isempty(varargin)
                n_cmd=length(varargin);
                stat_list=cell(n_cmd,1);
                % Send commands one by one as sending one query seems
                % to sometimes give errors if the string is very long
                for i=1:n_cmd
                    cmd = [varargin{i},';'];
                    Query(this.Device, this.address, cmd, this.QueryData);
                    stat_list{i} = char(ToString(this.QueryData));
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
                    Query(this.Device, this.address, cmd, this.QueryData);
                    res_list{i} = char(ToString(this.QueryData));
                end
            else
                res_list={};
            end
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

