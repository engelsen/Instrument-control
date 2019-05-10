classdef MyCollector < MySingleton

    properties (GetAccess = public, SetAccess = private, ...
            SetObservable = true)
        
        % Structure accomodating handles of instrument objects 
        InstrList = struct()
        
         % Properties of instruments
        InstrProps = struct()   
    end
    
    properties (Access = private)
        Listeners = struct()
        
        % Metadata indicating the state of Collector
        Metadata = MyMetadata.empty()
    end
    
    properties (Dependent = true)
        running_instruments
    end
    
    events
        NewDataWithHeaders
    end
    
    methods (Access = private)
        
        % The constructor of a singleton class must be private
        function this = MyCollector()
        end
    end
    
    methods (Access = public)
        function delete(this)
            cellfun(@(x) deleteListeners(this, x), ...
                this.running_instruments);
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
            
            % Read the settings of this instrument when new data is
            % acquired
            addParameter(p, 'collect_header', true, @islogical);
            
            parse(p, varargin{:});
            
            this.InstrList.(name) = Instrument;
            
            % Configure instrument properties
            this.InstrProps.(name) = struct( ...
                'collect_header',   p.Results.collect_header, ...
                'global_name',      '', ...
                'Gui',              []);
            
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
                
                this.InstrProps.(name).global_name = global_name;
            end
            
            if this.InstrProps.(name).collect_header && ...
                    ~ismethod(Instrument, 'readSettings')
                
                % If the class does not have a header generation function, 
                % it can still be added to the collector and transfer data
                % to Daq
                this.InstrProps.(name).collect_header = false;
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
                addlistener(this.InstrList.(name), ...
                'ObjectBeingDestroyed', ...
                @(~,~) instrumentDeletedCallback(this, name));
        end
        
        % Get existing instrument
        function Instr = getInstrument(this, name)
            assert(isfield(this.InstrList, name), ...
                ['Name must correspond to one of the running ' ...
                'instruments.'])
            
            Instr = this.InstrList.(name);
        end
        
        % Interface for accessing internally stored instrument properties
        function val = getInstrumentProp(this, instr_name, prop_name)
            assert(isfield(this.InstrProps, instr_name), ...
                ['''instr_name'' must correspond to one of the ' ...
                'running instruments.'])
            
            assert(isfield(this.InstrProps.(instr_name), prop_name), ...
                ['''prop_name'' must correspond to one of the following'...
                'instrument properties: ' ...
                var2str(fieldnames(this.InstrProps.(instr_name)))])
            
            val = this.InstrProps.(instr_name).(prop_name);
        end
        
        function setInstrumentProp(this, instr_name, prop_name, val)
            assert(isfield(this.InstrProps, instr_name), ...
                ['''instr_name'' must correspond to one of the ' ...
                'running instruments.'])
            
            assert(isfield(this.InstrProps.(instr_name), prop_name), ...
                ['''prop_name'' must correspond to one of the following'...
                'instrument properties: ' ...
                var2str(fieldnames(this.InstrProps.(instr_name)))])
            
            this.InstrProps.(instr_name).(prop_name) = val;
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
            
            % Indicate the name of acquiring instrument
            InstrEventData.src_name = name;
            
            % Collect the headers if the flag is on and if the triggering 
            % instrument does not request suppression of header collection
            if InstrEventData.new_header
                
                % Add the name of acquisition instrument
                AcqInstrMdt = MyMetadata('title', 'AcquiringInstrument');
                addParam(AcqInstrMdt, 'Name', InstrEventData.src_name);
                
                % Make the full metadata
                Mdt = [AcqInstrMdt, acquireHeaders(this)];
                
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
            
            for i = 1:length(this.running_instruments)
                name = this.running_instruments{i};
                
                if this.InstrProps.(name).collect_header
                    try
                        TmpMdt = readSettings(this.InstrList.(name));
                        TmpMdt.title = name;
                        Mdt = [Mdt, TmpMdt]; %#ok<AGROW>
                    catch ME
                        warning(['Error while reading metadata from ' ...
                            '%s. Measurement header collection is '...
                            'switched off for this instrument.' ...
                            '\nError: %s'], name, ME.message)
                        this.InstrProps.(name).collect_header = false;
                    end
                end
            end
            
            % Add field indicating the time when the trace was acquired
            TimeMdt = MyMetadata.time('title', 'AcquisitionTime');
            
            % Add the state of Collector
            CollMdt = getMetadata(this);
            
            Mdt = [TimeMdt, Mdt, CollMdt];
        end
        
        function bool = isrunning(this, name)
            assert(ischar(name)&&isvector(name),...
                'Instrument name must be a character vector, not %s',...
            class(name));
            bool = ismember(name, this.running_instruments);
        end
        
        % Remove instrument from collector without deleting the instrument 
        % object
        function removeInstrument(this, name)
            if isrunning(this, name)
                
                % Remove the instrument entries
                this.InstrList = rmfield(this.InstrList, name);
                this.InstrProps = rmfield(this.InstrProps, name);
                
                deleteListeners(this, name);
            end
        end
        
        % Delete all presesently running instruments
        function flush(this)
            instr_names = this.running_instruments;
            for i = 1:length(instr_names)
                nm = instr_names{i};
                
                % We rely on the deletion callbacks to do cleanup
                delete(this.InstrList.(nm));
            end
        end
    end
    
    methods (Access = private)
        function instrumentDeletedCallback(this, name)
            
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
            
            % Remove the instrument entry from Collector
            removeInstrument(this, name);
        end
        
        % Create metadata that stores information about the Collector 
        % state
        function Mdt = getMetadata(this)
            
            % Create new metadata if it has not yet been initialized
            if isempty(this.Metadata)
                this.Metadata = MyMetadata('title', 'SessionInfo');
                addParam(this.Metadata, 'instruments', {});
                addParam(this.Metadata, 'Props', struct());
            end
            
            % Update metadata parameters
            this.Metadata.ParamList.instruments = this.running_instruments;
                
            for fn = this.running_instruments'
                this.Metadata.ParamList.Props.(fn).collect_header = ...
                    this.InstrProps.collect_header;
                this.Metadata.ParamList.Props.(fn).is_global = ...
                    ~isempty(this.InstrProps.global_name);
                
                % Indicate if the instrument has gui
                this.Metadata.ParamList.Props.(fn).has_gui = ...
                    ~isempty(this.InstrProps.Gui);
            end
            
            Mdt = copy(this.Metadata);
        end
    end
    
    methods(Static = true)
        
        % Singletone constructor.
        function this = instance()
            persistent UniqueInstance

            if isempty(UniqueInstance)||(~isvalid(UniqueInstance))
                disp('Creating a new instance of MyCollector')
                this = MyCollector();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
    
    methods (Access = private)       
        function triggerNewDataWithHeaders(this, InstrEventData)
            notify(this, 'NewDataWithHeaders', InstrEventData);
        end

        %deleteListeners is in a separate file
        deleteListeners(this, obj_name);
    end
    
    methods
        function val = get.running_instruments(this)
            val = fieldnames(this.InstrList);
        end
    end
end
