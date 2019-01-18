classdef MyCollector < MySingleton & matlab.mixin.Copyable
    properties (Access=public, SetObservable=true)
        InstrList % Structure accomodating instruments 
        InstrProps % Properties of instruments
        MeasHeaders
        collect_flag
    end
    
    properties (Access=private)
        Listeners
    end
    
    properties (Dependent=true)
        running_instruments
    end
    
    events
        NewDataWithHeaders
    end
    
    methods (Access=private)
        % Constructor of a singleton class must be private
        function this=MyCollector(varargin)
            p=inputParser;
            addParameter(p,'InstrHandles',{});
            parse(p,varargin{:});
            
            this.collect_flag=true;
            
            if ~isempty(p.Results.InstrHandles)
                cellfun(@(x) addInstrument(this,x),p.Results.InstrHandles);
            end
            
            this.MeasHeaders=MyMetadata();
            this.InstrList=struct();  
            this.InstrProps=struct(); 
            this.Listeners=struct();
        end
    end
    
    methods (Access=public)
        
        function delete(this)
            cellfun(@(x) deleteListeners(this,x), this.running_instruments);
        end
        
        function addInstrument(this,instr_handle,varargin)
            p=inputParser;
            addParameter(p,'name','UnknownDevice',@ischar)
            parse(p,varargin{:});

            %Find a name for the instrument
            if ~ismember('name',p.UsingDefaults)
                name=p.Results.name;
            elseif isprop(instr_handle,'name') && ~isempty(instr_handle.name)
                name=genvarname(instr_handle.name, this.running_instruments);
            else
                name=genvarname(p.Results.name, this.running_instruments);
            end
            
            if ismethod(instr_handle, 'readHeader')
                %Defaults to read header
                this.InstrProps.(name).header_flag=true;
            else
                % If class does not have readHeader function, it can still
                % be added to the collector to transfer trace to Daq
                this.InstrProps.(name).header_flag=false;
                warning(['%s does not have a readHeader function, ',...
                    'measurement headers will not be collected from ',...
                    'this instrument.'],name)
            end
            this.InstrList.(name)=instr_handle;
            
            %If the added instrument has a newdata event, we add a listener for it.
            if contains('NewData',events(this.InstrList.(name)))
                this.Listeners.(name).NewData=...
                    addlistener(this.InstrList.(name),'NewData',...
                    @(~,InstrEventData) acquireData(this, InstrEventData));
            end
            
            %Cleans up if the instrument is closed
            this.Listeners.(name).Deletion=...
                addlistener(this.InstrList.(name),'ObjectBeingDestroyed',...
                @(~,~) deleteInstrument(this,name));
        end
        
        function acquireData(this, InstrEventData)
            src=InstrEventData.Source;
            
            % Check that event data object is MyNewDataEvent,
            % and fix otherwise
            if ~isa(InstrEventData,'MyNewDataEvent')
                InstrEventData=MyNewDataEvent();
                InstrEventData.new_header=true;
                InstrEventData.Trace=copy(src.Trace);
                try
                    InstrEventData.src_name=src.name;
                catch
                    InstrEventData.src_name='UnknownDevice';
                end
            end
            
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
                        TmpMetadata=readHeader(this.InstrList.(name));
                        addMetadata(this.MeasHeaders, TmpMetadata);
                    catch
                        warning(['Error while reading metadata from %s.',...
                            'Measurement header collection is switched ',...
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
        function running_instruments=get.running_instruments(this)
            running_instruments=fieldnames(this.InstrList);
        end
    end
end
