% Class for controlling the auto manifold of ColdEdge stinger cryostat.
% The manifold is controlled by an Arduino board that communicates with 
% computer via serial protocol. 

classdef MyCeCryo < MyInstrument
    
    properties
        valve_states
    end
    
    methods (Access=public)
        function this = MyCeCryo(interface, address)
            % A visa-serial Device object is created by the superclass 
            % constructor 
            % Below the serial port is configured according to the labview
            % program that came with the cryostat. 
            % These settings are the same as usual default, 
            % but still set them explicitly to be sure. 
            this.Device.BaudRate=9600;
            this.Device.DataBits=8;
            this.Device.FlowControl='none';
            this.Device.Parity='none';
            this.Device.StopBits=1;
            this.Device.DataTerminalReady='on';
            
            % Buffer size of 64 kB should be way an overkill. The labview
            % program provided by ColdEdge use 256 Bytes.
            this.Device.InputBufferSize=2^16;
            this.Device.OutputBufferSize=2^16;
            
            this.Device
        end
        
        function idn(this)
            this.idn_str=query(this.Device,'LAINI*');
        end
        
        function toggleValve(this, n)
            cmd=['LAcV',num2str(n),'*'];
            query(this.Device, cmd);
        end
    end
end

