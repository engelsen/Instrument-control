classdef MyCollector < MySingleton & matlab.mixin.Copyable
    properties (Access = public, SetObservable = true)
        InstrList    = struct()    % Structure accomodating instruments 
        InstrProps   = struct()    % Properties of instruments
        collect_flag = true
    end
    
    properties (Access = private)
        Listeners = struct()
    end
    
    properties (Dependent = true)
        running_instruments
    end
    
    events
        NewDataWithHeaders
    end
    
    methods (Access = private)
        
        % Constructor of a singleton class must be private
        function this = MyCollector(varargin)
            p = inputParser;
            addParameter(p,'InstrHandles',{});
            parse(p,varargin{:});
            
            if ~isempty(p.Results.InstrHandles)
                cellfun(@(x) addInstrument(this,x),p.Results.InstrHandles);
            end
        end
    end
    
    methods (Access = public)
        
        function delete(this)
            cellfun(@(x) deleteListeners(this,x), this.running_instruments);
        end
        
        function addInstrument(this, name, Instrument, varargin)
            assert(isvarname(name), ['Instrument name must be a valid ' ...
                'MATLAB variable name.'])
            
            assert(~ismember(name, this.running_instruments), ...
                ['Instrument ' name ' is already present in the ' ...
                'collector. Delete the existing instrument before ' ...
                'adding a new one with the same name.'])
            
            p = inputParser();
            
            % Optional - put the instrument in global workspace
            addParameter(p, 'make_global', true, @islogical);
            parse(p, varargin{:});
            
            this.InstrList.(name) = Instrument;
            
            % Configure instrument properties
            this.InstrProps.(name) = struct();
            this.InstrProps.(name).Gui = [];
            
            if p.Results.make_global
                global_name = name;
                
                % Assign instrument handle to a variable in global 
                % workspace for quick reference
                if isValidBaseVar(global_name)
                    base_ws_vars = evalin('base', 'who');
                    
                    warning(['A valid variable named ''' global_name ...
                        ''' already exists in global workspace.'])
                    
                    % Generate a new name excluding all the variable names 
                    % existing in the base workspace
                    global_name = matlab.lang.makeUniqueStrings( ...
                        global_name, base_ws_vars);
                end
                
                % Put the instrument in global workspace
                assignin('base', global_name, Instrument);
            else
                global_name = '';
            end
            this.InstrProps.(name).global_name = global_name;
            
            if ismethod(Instrument, 'readSettings')
                
                %Defaults to read header
                this.InstrProps.(name).header_flag = true;
            else
                
                % If the class does not have a header generation function, 
                % it can still be added to the collector and transfer data
                % to Daq
                this.InstrProps.(name).header_flag = false;
                warning(['%s does not have a readSettings function, ',...
                    'measurement headers will not be collected from ',...
                    'this instrument.'],name)
            end
            
            % If the added instrument has a newdata event, we add a 
            % listener for it.
            if ismember('NewData', events(this.InstrList.(name)))
                this.Listeners.(name).NewData = ...
                    addlistener(this.InstrList.(name),'NewData',...
                    @(~, EventData) acquireData(this, name, EventData));
            end
            
            %Cleans up if the instrument is closed
            this.Listeners.(name).Deletion = ...
                addlistener(this.InstrList.(name),'ObjectBeingDestroyed',...
                @(~,~) deleteInstrument(this, name));
        end
        
        % Store instrument GUI
        function addInstrumentGui(this, instr_name, Gui)
            assert(ismember(instr_name, this.running_instruments), ...
                'Name must correspond to one of the running instruments.')
            this.InstrProps.(instr_name).Gui = Gui;
        end
        
        % Get existing instrument GUI
        function Gui = getInstrumentGui(this, instr_name)
            assert(ismember(instr_name, this.running_instruments), ...
                'Name must correspond to one of the running instruments.')
            
            try
                assert(isvalid(this.InstrProps.(instr_name).Gui), '');
                Gui = this.InstrProps.(instr_name).Gui;
            catch
                Gui = [];
            end
        end
        
        function acquireData(this, name, InstrEventData)
            src = InstrEventData.Source;
            
            % Check that event data object is MyNewDataEvent,
            % and fix otherwise
            if ~isa(InstrEventData,'MyNewDataEvent')
                InstrEventData = MyNewDataEvent();
                InstrEventData.new_header = true;
                InstrEventData.Trace = copy(src.Trace);
            end
            
            % Add instrument name
            InstrEventData.src_name = name;
            
            % Collect the headers if the flag is on and if the triggering 
            % instrument does not request suppression of header collection
            if this.collect_flag && InstrEventData.new_header
                
                % Add field indicating the time when the trace was acquired
                TimeMdt = MyMetadata.time('title', 'AcquisitionTime');
                
                AcqInstrMdt = MyMetadata('title', 'AcquiringInstrument');
                addParam(AcqInstrMdt, 'Name', InstrEventData.src_name);
                
                % Make the full metadata
                Mdt = [AcqInstrMdt, TimeMdt, acquireHeaders(this)];
                
                %We copy the MeasHeaders to both copies of the trace - the
                %one that is with the source and the one that is forwarded
                %to Daq.
                InstrEventData.Trace.MeasHeaders = copy(Mdt);
                src.Trace.MeasHeaders = copy(Mdt);
            end
            
            triggerNewDataWithHeaders(this, InstrEventData);
        end
        
        % Collects headers for open instruments with the header flag on
        function Mdt = acquireHeaders(this)
            Mdt = MyMetadata.empty();
            
            for i=1:length(this.running_instruments)
                name = this.running_instruments{i};
                
                if this.InstrProps.(name).header_flag
                    try
                        TmpMdt = readSettings(this.InstrList.(name));
                        TmpMdt.title = name;
                        Mdt = [Mdt, TmpMdt]; %#ok<AGROW>
                    catch ME
                        warning(['Error while reading metadata from %s. '...
                            'Measurement header collection is switched '...
                            'off for this instrument.\nError: %s'], ...
                            name, ME.message)
                        this.InstrProps.(name).header_flag = false;
                    end
                end
            end
        end
        
        function bool = isrunning(this, name)
            assert(ischar(name)&&isvector(name),...
                'Instrument name must be a character vector, not %s',...
            class(name));
            bool = ismember(name, this.running_instruments);
        end
        
        function deleteInstrument(this,name)
            if isrunning(this, name)
                
                % Clear the base workspace wariable
                gn = this.InstrProps.(name).global_name;
                if ~isempty(gn)
                    try
                        evalin('base', sprintf('clear(''%s'');', gn));
                    catch ME
                        warning(['Could not clear global variable ''' ...
                            gn '''. Error: ' ME.message]);
                    end
                end
                
                % Remove the instrument
                this.InstrList = rmfield(this.InstrList, name);
                this.InstrProps = rmfield(this.InstrProps, name);
                deleteListeners(this, name);
            end
        end
        
    end
    
    methods(Static = true)
        
        % Concrete implementation of the singletone constructor.
        function this = instance()
            persistent UniqueInstance

            if isempty(UniqueInstance)||(~isvalid(UniqueInstance))
                disp('Creating new instance of MyCollector')
                this = MyCollector();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
    
    methods (Access = private)       
        function triggerNewDataWithHeaders(this, InstrEventData)
            notify(this,'NewDataWithHeaders', InstrEventData);
        end

        %deleteListeners is in a separate file
        deleteListeners(this, obj_name);
    end
    
    methods
        function running_instruments = get.running_instruments(this)
            running_instruments = fieldnames(this.InstrList);
        end
    end
end
