% Class containing ConstructionParser that can be used to automatically 
% assign public properties during construction of subclasses
classdef MyInputHandler < handle
    
    properties (SetAccess=protected, GetAccess=public)
        %Input parser for class constructor
        ConstructionParser;
    end
    
    methods
        function this = MyInputHandler(varargin)
            createConstructionParser(this);
            parseClassInputs(this, varargin{:});
        end
    end
    
    methods (Access=protected)
        % Create parser. Can contain parameter additions 
        % if overloaded in a subclass 
        function p = createConstructionParser(this)
            p=inputParser();
            this.ConstructionParser=p;
            addClassProperties(this);
        end
        
        % Add all the properties the class which are not already  present  
        % in the scheme of ConstructionParser and which have set access 
        % permitted for MyInputHandler 
        function addClassProperties(this)
            thisMetaclass = metaclass(this);    
            for i=1:length(thisMetaclass.PropertyList)
                Tmp = thisMetaclass.PropertyList(i);
                
                % If parameter is already present in the parser scheme,
                % skip
                if ismember(Tmp.Name, this.ConstructionParser.Parameters)
                    continue
                end
                
                % Constant, Dependent and Abstract propeties cannot be set,
                % so skip in this case also.
                if Tmp.Constant||Tmp.Abstract||Tmp.Dependent
                    continue
                end
                
                % Check if MyInputHandler has access to the property. This 
                % can be true in two cases: 1) SetAccess is public 
                % 2) MyInputHandler class was explicitly given access 
                sa=Tmp.SetAccess;
                if ischar(sa)
                    has_access=strcmpi(sa,'public');
                elseif iscell(sa)
                    % Case when SetAcces is specified as cell array of
                    % metaclasses
                    has_access = any(...
                        cellfun(@(x) strcmpi(x.Name,'MyInputHandler'),sa));
                else
                    has_access=false;
                end
                
                % If has set access, add parameter to the parser scheme
                if has_access
                    if Tmp.HasDefault
                        def = Tmp.DefaultValue;
                        % Create validation function based on the class of
                        % default value
                        val_fcn = @(x)isa(x, class(def));
                    else
                        def = [];
                        val_fcn = @(x)true;
                    end
                    addParameter(this.ConstructionParser,...
                        Tmp.Name, def, val_fcn);
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

