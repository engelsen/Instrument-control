% Class containing ConstructionParser that can be used to automatically 
% assign public properties during construction of subclasses
classdef MyInputHandler < handle
    
    properties (SetAccess=protected, GetAccess=public)
        %Input parser for class constructor
        ConstructionParser;
    end
    
    methods (Access=protected)
        % Create parser. Can contain parameter additions 
        % if overloaded in a subclass 
        function p = createConstructionParser(this)
            p=inputParser();
            this.ConstructionParser=p;
        end
        
        % Add all the properties the class which are not present in the 
        % scheme of ConstructionParser and which have public set acces 
        % to the scheme of ConstructionParser 
        function addClassProperties(this)
            thisMetaclass = metaclass(this);    
            for i=1:length(thisMetaclass.PropertyList)
                Tmp = thisMetaclass.PropertyList(i);
                % Constant, Dependent and Abstract propeties cannot be set
                if (~Tmp.Constant)&&(~Tmp.Abstract)&&(~Tmp.Dependent)&&...
                        strcmpi(Tmp.SetAccess,'public')&&...
                        (~ismember(Tmp.Name,...
                        this.ConstructionParser.Parameters))
                    if Tmp.HasDefault
                        def = Tmp.DefaultValue;
                    else
                        def = [];
                    end
                    addParameter(this.ConstructionParser, Tmp.Name, def);
                end
            end
        end
        
        % parse varargin and assign results to class properties 
        % with the same names as parameters 
        function parseClassInputs(this, varargin)  
            parse(this.ConstructionParser, varargin{:});  
            % assign results that have associated class properties with
            % public set access
            for i=1:length(this.ConstructionParser.Parameters)
                par = this.ConstructionParser.Parameters{i};
                if ~ismember(par, this.ConstructionParser.UsingDefaults)&&...
                        isprop(this, par)
                    try
                        this.(par) = this.ConstructionParser.Results.(par);
                    catch
                        warning(['Value of the input parameter ''',...
                            par,''' could not be assigned to property'])
                    end 
                end
            end 
        end
        
    end
end

