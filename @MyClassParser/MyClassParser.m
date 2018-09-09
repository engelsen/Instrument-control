% Input parser, which functionality was extended to automatically add
% class properties to the scheme and assign the results after parsing is
% done

classdef MyClassParser < inputParser
    
    methods (Access=public)
        function this = MyClassParser(varargin)
            this@inputParser();
            
            if nargin()==1
                % If an object is supplied via varargin, add its properties
                % to the parser scheme
                addClassProperties(this, varargin{1});
            end
        end

        % Add all the properties the class which are not already  present  
        % in the scheme of the parser and which have set access 
        % permitted for MyClassParser 
        function addClassProperties(this, obj)
            objMetaclass = metaclass(obj);    
            for i=1:length(objMetaclass.PropertyList)
                Tmp = objMetaclass.PropertyList(i);
                
                % If parameter is already present in the parser scheme,
                % skip
                if ismember(Tmp.Name, this.Parameters)
                    continue
                end
                
                % Constant, Dependent and Abstract propeties cannot be set,
                % so skip in this case also.
                if Tmp.Constant||Tmp.Abstract||Tmp.Dependent
                    continue
                end
                
                % Check if the parser has access to the property. This 
                % can be true in two cases: 1) SetAccess is public 
                % 2) MyClassParser class was explicitly given access 
                sa=Tmp.SetAccess;
                if ischar(sa)
                    has_access=strcmpi(sa,'public');
                elseif iscell(sa)
                    % Case when SetAcces is specified as cell array of
                    % metaclasses
                    has_access = any(...
                        cellfun(@(x) strcmpi(x.Name, class(this)),sa));
                else
                    has_access=false;
                end
                
                % If has set access, add parameter to the parser scheme
                if has_access
                    if Tmp.HasDefault
                        def = Tmp.DefaultValue;
                        % Create validation function based on the class of
                        % default value
                        val_fcn = @(x)assert(isa(x, class(def)),...
                            ['The value must be of the class ',class(def),...
                            ' while the present one is of the class ',...
                            class(x),'.']);
                    else
                        def = [];
                        val_fcn = @(x)true;
                    end
                    addParameter(this, Tmp.Name, def, val_fcn);
                end
            end
        end
        
        
        % parse varargin and assign results to class properties 
        % with the same names as parameters 
        function processInputs(this, obj, varargin)  
            parse(this, varargin{:});  
            % assign results that have associated class properties with
            % public set access
            for i=1:length(this.Parameters)
                par = this.Parameters{i};
                if ~ismember(par, this.UsingDefaults)&&...
                        isprop(obj, par)
                    try
                        obj.(par) = this.Results.(par);
                    catch
                        warning(['Value of the input parameter ''',...
                            par,''' could not be assigned to property'])
                    end 
                end
            end 
        end

    end
    
end

