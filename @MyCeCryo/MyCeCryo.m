% Class for controlling the auto manifold of ColdEdge stinger cryostat.
% The manifold is managed by an Arduino board that communicates with 
% computer via serial protocol. 

classdef MyCeCryo < MyScpiInstrument
    
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        
        % If a long term operation (e.g. starting a cooldown or pumping the 
        % capillary) is in progress
        operation_in_progress
        
        % Time for the recirculator to pump down helium from the capillary 
        % before closing it off
        tr = 20
    end
    
    properties (Access = protected)
        Timer
    end
    
    methods (Access = public)
        function this = MyCeCryo(interface, address, varargin)
            this@MyScpiInstrument(interface, address, varargin{:});
            
            this.Timer = timer();
            
            % Buffer size of 64 kB should be way an overkill. The labview
            % program provided by ColdEdge use 256 Bytes.
            this.Device.InputBufferSize=2^16;
            this.Device.OutputBufferSize=2^16;
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
            
            writePropertyHedged(this, ...
                'valve1',       false, ...
                'valve2',       false, ...
                'valve3',       false, ...
                'valve4',       false, ...
                'valve5',       false, ...
                'valve7',       false, ...
                'recirc',       false, ...
                'cryocooler',   false);
        end
        
        function startCooldown(this)
            assert(~this.operation_in_progress, ['Cannot initiate' ...
                ' cooldown stop. Another operation is in progress.'])
            
            writePropertyHedged(this, ...
                'valve2',       false, ...
                'valve3',       false, ...
                'valve5',       false, ...
                'valve7',       false);
            
            writePropertyHedged(this, ...
                'valve1',       true, ...
                'valve4',       true, ...
                'recirc',       true, ...
                'cryocooler',   true);
        end
        
        function stopCooldown(this)
            function switchRecirculatorOff(~, ~)
                writePropertyHedged(this, ...
                    'valve1',       false, ...
                    'valve2',       false, ...
                    'valve3',       false, ...
                    'valve4',       false);
                
                % Switch off the recirculator after all the valves are
                % closed
                writePropertyHedged(this, 'recirc', false);
                
                this.operation_in_progress = false;
            end
            
            assert(~this.operation_in_progress, ['Cannot initiate' ...
                ' cooldown stop. Another operation is in progress.'])
            
            % Switch off the cryocooler, close the recirculator supply 
            % valve (1) and at the same time open the valves bridging the 
            % recirculator return and supply (2 and 3).
            writePropertyHedged(this, ...
                'valve1',       false, ...
                'valve2',       true, ...
                'valve3',       true, ...
                'cryocooler',   false);
            
            % Wait for the helium to be pumped out of the capillary by the
            % recirculator and then switch the recirculator off
            this.Timer.ExecutionMode = 'singleShot';
            this.Timer.StartDelay = this.tr;
            this.Timer.TimerFcn = @switchRecirculatorOff;
            
            start(this.Timer);
            this.operation_in_progress = true;
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            % Valve states
            for i=1:7
                if i == 6
                    continue % No valve 6
                end
                
                tag = sprintf('valve%i',i);
                cmd = sprintf(':VALVE%i',i);
                addCommand(this, tag, cmd,...
                    'default',  false, ...
                    'fmt_spec', '%b', ...
                    'info',     'Valve open(true)/clsed(false)');
            end
            
            addCommand(this, 'recirc', ':REC',...
                'default',  false, ...
                'fmt_spec', '%b', ...
                'info',     'Recirculator on/off');
            
            addCommand(this, 'cryocooler', ':COOL',...
                'default',  false, ...
                'fmt_spec', '%b', ...
                'info',     'Cryocooler on/off');
            
            addCommand(this, 'press', ':PRES',...
                'default',  false, ...
                'fmt_spec', '%e', ...
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

