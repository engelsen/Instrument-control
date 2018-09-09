% Class containing ConstructionParser that can be used to automatically 
% assign public properties during construction of subclasses
classdef MyInputHandler < handle
    
    properties (SetAccess=protected, GetAccess=public)
        %Input parser for class constructor
        ConstructionParser
    end
    
    methods
        function this = MyInputHandler(varargin)
            p = this.createConstructionParser(metaclass(this));
            this.ConstructionParser=p;
            parseClassInputs(p, this, varargin{:});
        end
    end
    
    
    methods (Static)

        function p = createConstructionParser(metaclass)
            p=MyConstructionParser();
            addClassProperties(p, metaclass);
        end
        
        function getParserParams(metaclass)
            p = createParser(metaclass);
            p.Parameters;
        end
        
    end

end

