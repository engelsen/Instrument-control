classdef MyCollector < handle & matlab.mixin.Copyable
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
    
    methods (Access=public)
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
            
            %We add only classes that have readHeaders functionality
            if contains('readHeader',methods(instr_handle))
                %Defaults to read header
                this.InstrProps.(name).header_flag=true;
                this.InstrList.(name)=instr_handle;
            else
                error(['%s does not have a readHeader function,',...
                    ' cannot be added to Collector'],name)
            end
            
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
        
        function acquireData(this,InstrEventData)
            src=InstrEventData.Source;
            %Collect the headers if the flag is on
            if this.collect_flag     
                this.MeasHeaders=MyMetadata();
                addField(this.MeasHeaders,'AcquiringInstrument')
                if isprop(src,'name')
                    name=src.name;
                else
                    name='Not Accessible';
                end
                addParam(this.MeasHeaders,'AcquiringInstrument',...
                    'Name',name);
                acquireHeaders(this);
                %We copy the MeasHeaders to the trace.
                src.Trace.MeasHeaders=copy(this.MeasHeaders);
            end
            
            triggerNewDataWithHeaders(this,InstrEventData);
        end
        
        %Collects headers for open instruments with the header flag on
        function acquireHeaders(this)
            for i=1:length(this.running_instruments)
                name=this.running_instruments{i};
                
                if this.InstrProps.(name).header_flag
                    TmpMetadata=readHeader(this.InstrList.(name));
                    addMetadata(this.MeasHeaders, TmpMetadata);
                end
            end
        end
        
        function clearHeaders(this)
            this.MeasHeaders=MyMetadata();
        end
        
        function bool=isrunning(this,name)
            assert(~isempty(name),'Instrument name must be specified')
            assert(ischar(name),...
                'Instrument name must be a character, not %s',...
            class(name));
            bool=ismember(this.running_instruments,name);
        end
    end
    
    methods (Access=private)       
        function triggerNewDataWithHeaders(this,InstrEventData)
            % in EventData pass information about the instrument
            EventData = MyNewDataEvent();
            EventData.InstrEventData = InstrEventData;
            notify(this,'NewDataWithHeaders',EventData);
        end

        %deleteListeners is in a separate file
        deleteListeners(this, obj_name);
        
        function deleteInstrument(this,name)
            %We remove the instrument
            this.InstrList=rmfield(this.InstrList,name);
            this.InstrProps=rmfield(this.InstrProps,name);
            deleteListeners(this,name);
        end
    end
    
    methods
        function running_instruments=get.running_instruments(this)
            running_instruments=fieldnames(this.InstrList);
        end
    end
end
