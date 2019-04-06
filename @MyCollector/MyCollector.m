classdef MyCollector < MySingleton & matlab.mixin.Copyable
    properties (Access = public, SetObservable = true)
        InstrList = struct()    % Structure accomodating instruments 
        InstrProps = struct()   % Properties of instruments
        MeasHeaders
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
            
            this.MeasHeaders = MyMetadata();
        end
    end
    
    methods (Access=public)
        
        function delete(this)
            cellfun(@(x) deleteListeners(this,x), this.running_instruments);
        end
        
        function addInstrument(this, name, Instrument)
            assert(isvarname(name), ['Instrument name must be a valid ' ...
                'MATLAB variable name.'])
            
            assert(~ismember(name, this.running_instruments), ...
                ['Instrument ' name ' is already present in the ' ...
                'collector. Delete the existing instrument before ' ...
                'adding a new one with the same name.'])
            
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
            this.InstrList.(name) = instr_handle;
            
            % If the added instrument has a newdata event, we add a 
            % listener for it.
            if ismember('NewData', events(this.InstrList.(name)))
                this.Listeners.(name).NewData=...
                    addlistener(this.InstrList.(name),'NewData',...
                    @(~, EventData) acquireData(this, name, EventData));
            end
            
            %Cleans up if the instrument is closed
            this.Listeners.(name).Deletion=...
                addlistener(this.InstrList.(name),'ObjectBeingDestroyed',...
                @(~,~) deleteInstrument(this,name));
        end
        
        % Store instrument GUI
        function addInstrumentGui(this, instr_name, Gui)
            assert(ismember(instr_name, this.running_instruments), ...
                'Name must correspond to one of the running instruments.')
            this.InstrProps.(name).Gui = Gui;
        end
        
        % Store instrument GUI
        function Gui = getInstrumentGui(this, instr_name)
            assert(ismember(instr_name, this.running_instruments), ...
                'Name must correspond to one of the running instruments.')
            
            if isfield(this.InstrProps.(name), 'Gui') && ...
                    isvalid(this.InstrProps.(name).Gui)
                Gui = this.InstrProps.(name).Gui;
            else
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
                this.MeasHeaders=MyMetadata();
                %Add field indicating the time when the trace was acquired
                addTimeField(this.MeasHeaders, 'AcquisitionTime')
                addField(this.MeasHeaders,'AcquiringInstrument')
                %src_name is a valid matlab variable name as ensured by 
                %its set method
                addParam(this.MeasHeaders,'AcquiringInstrument',...
                    'Name', InstrEventData.src_name);
                acquireHeaders(this);
                
                %We copy the MeasHeaders to both copies of the trace - the
                %one that is with the source and the one that is forwarded
                %to Daq.
                InstrEventData.Trace.MeasHeaders=copy(this.MeasHeaders);
                src.Trace.MeasHeaders=copy(this.MeasHeaders);
            end
            
            triggerNewDataWithHeaders(this,InstrEventData);
        end
        
        %Collects headers for open instruments with the header flag on
        function acquireHeaders(this)
            for i=1:length(this.running_instruments)
                name=this.running_instruments{i};
                
                if this.InstrProps.(name).header_flag
                    try
                        TmpMetadata=readSettings(this.InstrList.(name));
                        addMetadata(this.MeasHeaders, TmpMetadata);
                    catch
                        warning(['Error while reading metadata from %s. '...
                            'Measurement header collection is switched '...
                            'off for this instrument.'],name)
                        this.InstrProps.(name).header_flag=false;
                    end
                    
                end
            end
        end
        
        function clearHeaders(this)
            this.MeasHeaders=MyMetadata();
        end
        
        function bool=isrunning(this,name)
            assert(~isempty(name),'Instrument name must be specified')
            assert(ischar(name)&&isvector(name),...
                'Instrument name must be a character vector, not %s',...
            class(name));
            bool=ismember(name,this.running_instruments);
        end
        
        function deleteInstrument(this,name)
            if isrunning(this,name)
                
                %We remove the instrument
                this.InstrList=rmfield(this.InstrList,name);
                this.InstrProps=rmfield(this.InstrProps,name);
                deleteListeners(this,name);
            end
        end
        
    end
    
    methods(Static)
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
    
    methods (Access=private)       
        function triggerNewDataWithHeaders(this,InstrEventData)
            notify(this,'NewDataWithHeaders',InstrEventData);
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
