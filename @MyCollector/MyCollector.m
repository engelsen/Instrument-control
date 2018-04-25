classdef MyCollector < handle
    properties (Access=public, SetObservable=true)
        InstrProps=struct();
        InstrList=struct();
        MeasHeaders=struct();
        collect_flag;
    end
    
    properties (Access=private)
        Listeners=struct();
    end
    
    properties (Dependent=true)
        open_instruments;
    end
    
    events
        NewMeasHeaders;
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
        
        function addInstrument(this,instr_handle)
            %Input check
            assert(ischar(instr_handle.name),...
                'The instrument name must be a char')
            name=instr_handle.name;
            
            %We add only MyInstrument classes for now
            if contains('MyInstrument',superclasses(instr_handle))
                %Defaults to read header
                this.InstrProps.(name).header_flag=true;
                this.InstrList.(name)=instr_handle;
            else
                error(['%s is not a subclass of MyInstrument,',...
                    ' cannot be added to instrument list'],name)
            end
            
            %If the added instrument has a newdata event, we add a listener for it.
            if contains('NewData',events(instr_handle))
                this.Listeners.(name).NewData=...
                    addlistener(this.InstrList.(name),'NewData',...
                    @(src,~) collectHeaders(this,src));
            end
            
            %Cleans up if the instrument is closed
            this.Listeners.(name).Deletion=...
                addlistener(this.InstrList.(name),'ObjectBeingDestroyed',...
                @(~,~) deleteInstrument(this,name));
            

        end
        
        function collectHeaders(this,src)
            %If the collect flag is not active, do nothing
            if ~this.collect_flag; return; end
            
            if isprop(src,'Trace') && isprop(src.Trace,'uid')
                this.MeasHeaders=MyMetadata('uid',src.Trace.uid);
            else
                this.MeasHeaders=MyMetadata();
            end
            
            acquireHeaders(this);
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
            
            %Triggers the event showing measurement headers are ready
            triggerMeasHeaders(this);
        end
        
        function clearHeaders(this)
            this.MeasHeaders=MyMetadata();
        end

    end
    
    methods (Access=private)
        function triggerMeasHeaders(this)
            notify(this,'NewMeasHeaders');
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
