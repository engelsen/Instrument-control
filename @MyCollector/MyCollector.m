classdef MyCollector < handle & matlab.mixin.Copyable
    properties (Access=public, SetObservable=true)
        InstrProps=struct();
        InstrList=struct();
        MeasHeaders=MyMetadata();
        Data=MyTrace();
        collect_flag;
    end
    
    properties (Access=private)
        Listeners=struct();
    end
    
    properties (Dependent=true)
        open_instruments;
    end
    
    events
        NewDataCollected;
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
        end
        
        function delete(this)
            cellfun(@(x) deleteListeners(this,x), this.open_instruments);
        end
        
        function addInstrument(this,prog_handle,varargin)
            p=inputParser;
            addParameter(p,'name','UnknownDevice',@ischar)
            parse(p,varargin{:});
            
            %Find a name for the instrument
            if ~ismember('name',p.UsingDefaults)
                name=erase(p.Results.name,' ');
            elseif isprop(prog_handle,'name') && ~isempty(prog_handle.name)
                name=prog_handle.name;
            elseif ~isempty(findMyInstrument(prog_handle))
                h_instr=findMyInstrument(prog_handle);
                if isprop(h_instr,'name') && ~isempty(h_instr.name)
                    name=h_instr.name;
                else
                    name=p.Results.name;
                end
            else
                name=p.Results.name;
            end
            
            %We add only classes that have readHeaders functionality
            if contains('readHeader',methods(prog_handle))
                %Defaults to read header
                this.InstrProps.(name).header_flag=true;
                this.InstrList.(name)=prog_handle;
            elseif contains('readHeader',...
                    methods(findMyInstrument(prog_handle)))
                %Defaults to read header
                this.InstrProps.(name).header_flag=true;
                this.InstrList.(name)=findMyInstrument(prog_handle);
            else
                error(['%s does not have a readHeaders function,',...
                    ' cannot be added to Collector'],name)
            end
            
            %If the added instrument has a newdata event, we add a listener for it.
            if contains('NewData',events(this.InstrList.(name)))
                this.Listeners.(name).NewData=...
                    addlistener(this.InstrList.(name),'NewData',...
                    @(src,~) acquireData(this,src));
            end
            
            %Cleans up if the instrument is closed
            this.Listeners.(name).Deletion=...
                addlistener(this.InstrList.(name),'ObjectBeingDestroyed',...
                @(~,~) deleteInstrument(this,name));
        end
        
        function acquireData(this,src)
            %Copy the data from the instrument. 
            this.Data=copy(src.Trace);
            
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
                    'Name',name,'%s');
                acquireHeaders(this);
                %We copy the MeasHeaders to the trace.
                this.Data.MeasHeaders=copy(this.MeasHeaders);
            end
            
            triggerNewDataCollected(this,'tag',src.name);
        end
        
        %Collects headers for open instruments with the header flag on
        function acquireHeaders(this)
            for i=1:length(this.open_instruments)
                name=this.open_instruments{i};
                
                if this.InstrProps.(name).header_flag
                    tmp_struct=readHeader(this.InstrList.(name));
                    addField(this.MeasHeaders,name);
                    addStructToField(this.MeasHeaders,name,tmp_struct);
                end
            end
        end
        
        function clearHeaders(this)
            this.MeasHeaders=MyMetadata();
        end
        
        function Trace=getTrace(this,name)
            assert(isopen(this,name),'%s is not an open instrument');
            assert(isprop(this.InstrList.(name),'Trace'),...
                'Cannot get trace, %s does not have a Trace property',...
                name);
            Trace=this.InstrList.(name).Trace;
        end
        
        function bool=isopen(this,name)
            assert(~isempty(name),'Instrument name must be specified')
            assert(ischar(name),...
                'Instrument name must be a character, not %s',...
            class(name));
            bool=ismember(this.open_instruments,name);
        end
    end
    
    methods (Access=private)
        function triggerMeasHeaders(this)
            notify(this,'NewMeasHeaders');
        end
        
        function triggerNewDataCollected(this,varargin)
            p=inputParser;
            addParameter(p,'tag','',@ischar);
            parse(p,varargin{:});
            %Load the information into event data.
            eventdata=MyNewDataEvent('src_tag',p.Results.tag);
            notify(this,'NewDataCollected',eventdata);
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
        function open_instruments=get.open_instruments(this)
            open_instruments=fieldnames(this.InstrList);
        end
    end
end
