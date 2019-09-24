% Class for controlling the auto manifold of ColdEdge stinger cryostat.
% The manifold is managed by an Arduino board that communicates with 
% computer via serial protocol. 

classdef MyColdEdgeCryo < MyScpiInstrument & MyCommCont & MyGuiCont
    
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        
        % If a long term operation (e.g. starting a cooldown or pumping the 
        % capillary) is in progress
        operation_in_progress
        
        % Time for the recirculator to pump down helium from the capillary 
        % before closing it off
        tr = 900
    end
    
    properties (Access = protected)
        Timer
    end
    
    methods (Access = public)
        function this = MyColdEdgeCryo(varargin)
            P = MyClassParser(this);
            addParameter(P, 'enable_gui', false);
            processInputs(P, this, varargin{:});
            
            this.Timer = timer();
            
            % Buffer size of 64 kByte should be way an overkill.
            this.Device.InputBufferSize = 2^16;
            this.Device.OutputBufferSize = 2^16;
            
            connect(this);
            createCommandList(this);
             
            if P.Results.enable_gui
                createGui(this);
            end
        end
        
        function delete(this)
            try
                stop(this.Timer);
            catch ME
                warning(ME.message);
            end
            
            try
                delete(this.Timer);
            catch ME
                warning(ME.message);
            end
        end
        
        % Abort the current operation
        function abort(this)
            stop(this.Timer);
            this.operation_in_progress = false;
            
            this.auto_sync = false;
            
            this.valve1 = false;
            this.valve2 = false;
            this.valve3 = false;
            this.valve4 = false;
            this.valve5 = false;
            this.valve7 = false;
            this.recirc = false;
            this.cryocooler = false;
            
            % Sync once
            sync(this);
            
            % Return to the hedged mode
            this.auto_sync = true;
        end
        
        function startCooldown(this)
            assert(~this.operation_in_progress, ['Cannot initiate' ...
                ' cooldown stop. Another operation is in progress.'])
            
            this.auto_sync = false;
            
            this.valve2 = false;
            this.valve3 = false;
            this.valve5 = false;
            this.valve7 = false;
            
            % Open the recirculator path, starting from the return
            this.valve4 = true;
            this.valve1 = true;
            
            % Start the compressors
            this.recirc = true;
            this.cryocooler = true;
            
            % Sync once
            sync(this);
            
            % Return to the hedged mode
            this.auto_sync = true;
        end
        
        function stopCooldown(this)
            function switchRecirculatorOff(~, ~)
                this.auto_sync = false;
                
                % Close the recirculator path, starting from the supply
                this.valve1 = false;
                this.valve4 = false;
                
                % Switch off the recirculator after all the valves are
                % closed
                this.recirc = false;
                
                sync(this);
                this.auto_sync = true;
                
                this.operation_in_progress = false;
            end
            
            assert(~this.operation_in_progress, ['Cannot initiate' ...
                ' cooldown stop. Another operation is in progress.'])
            
            this.auto_sync = false;
            
            % Switch off the cryocooler, close the recirculator supply 
            % valve (1).
            this.valve1 = false;
            this.cryocooler = false;
            
            sync(this);
            this.auto_sync = true;
            
            % Wait for the helium to be pumped out of the capillary by the
            % recirculator and then switch the recirculator off
            this.Timer.ExecutionMode = 'singleShot';
            this.Timer.StartDelay = this.tr;
            this.Timer.TimerFcn = @switchRecirculatorOff;
            
            start(this.Timer);
            this.operation_in_progress = true;
        end
        
        % Overload writeSettings method of MyInstrument
        function writeSettings(this)
            disp(['The settings of ' class(this) ' cannot be loaded ' ...
                'for safety considerations. Please configure the ' ...
                'instrument manually'])
            return
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % Valve states
            for i = 1:7
                if i == 6
                    continue % There is no valve 6
                end
                
                tag = sprintf('valve%i',i);
                cmd = sprintf(':VALVE%i',i);
                
                addCommand(this, tag, cmd, ...
                    'format',   '%b', ...
                    'info',     'Valve open(true)/clsed(false)');
            end
            
            addCommand(this, 'recirc', ':REC', ...
                'format',   '%b', ...
                'info',     'Recirculator on/off');
            
            addCommand(this, 'cryocooler', ':COOL', ...
                'format',   '%b', ...
                'info',     'Cryocooler on/off');
            
            addCommand(this, 'press', ':PRES', ...
                'format',   '%e', ...
                'access',   'r', ...
                'info',     'Supply pressure (PSI)');
        end
    end
    
    methods        
        function val = get.operation_in_progress(this)
            try
                val = strcmpi(this.Timer.Running, 'on');
            catch ME
                warning(ME.message);
                val = false;
            end
        end
    end
end

