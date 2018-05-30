%Class for NewData/NewDataCollected events
classdef MyNewDataEvent < event.EventData
    properties
        src_tag;
    end
    
    methods
        function this=MyNewDataEvent(varargin)
            p=inputParser;
            addParameter(p,'src_tag',[],@ischar);
            parse(p,varargin{:})
            
            %Load parameters into class
            for i=1:length(p.Results)
                if isprop(this, p.Parameters{i})
                    this.(p.Parameters{i})= p.Results.(p.Parameters{i});
                end
            end
        end
    end
end