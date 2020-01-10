% Input parser, which functionality was extended to automatically add
% class properties to the scheme and assign the results after parsing is
% done.

classdef MyClassParser < inputParser
    
    methods (Access = public)
        function this = MyClassParser(varargin)
            this@inputParser();
            
            if nargin() == 1
                
                % If an object is supplied via varargin, add its properties
                % to the parser scheme
                addClassProperties(this, varargin{1});
            end
        end

        % Add all the properties the class which are not already  present  
        % in the scheme of the parser and which have set access 
        % permitted for MyClassParser 
        function addClassProperties(this, Obj)
            ObjMetaclass = metaclass(Obj); 
            
            for i=1:length(ObjMetaclass.PropertyList)
                TmpMpr = ObjMetaclass.PropertyList(i);
                
                % If parameter is already present in the parser scheme,
                % skip
                if ismember(TmpMpr.Name, this.Parameters)
                    continue
                end
                
                % Constant, Dependent and Abstract propeties cannot be set,
                % so skip in this case also.
                if TmpMpr.Constant || TmpMpr.Abstract || ...
                        (TmpMpr.Dependent && isempty(TmpMpr.SetMethod))
                    continue
                end
                
                % Check if the parser has access to the property. This 
                % can be true in two cases: 1) SetAccess is public 
                % 2) MyClassParser class was explicitly given access 
                sa = TmpMpr.SetAccess;
                if ischar(sa)
                    has_access = strcmpi(sa, 'public');
                elseif iscell(sa)
                    
                    % Case when SetAcces is specified as cell array of
                    % metaclasses
                    has_access = any(...
                        cellfun(@(x) strcmpi(x.Name, class(this)), sa));
                else
                    has_access = false;
                end
                
                if ~has_access
                    
                    % Return if the parser does not have access to the
                    % property
                    continue
                end
                
                % Determine the default value and validation function
                if TmpMpr.HasDefault
                    def = TmpMpr.DefaultValue;
                else
                    def = [];
                end
                
                if isempty(TmpMpr.SetMethod) && TmpMpr.HasDefault
                    
                    % Create validation function based on the class of
                    % default value
                    validationFcn = @(x)assert(isa(x, class(def)),...
                        ['The value must be of the class ' ...
                        class(def) ' while the present one is ' ...
                        'of the class ' class(x) '.']);                        
                    opt_vars = {def, validationFcn};
                else
                    
                    % Validation is either done by the set method
                    % defined in the object class or completely absent
                    opt_vars = {def};
                end
                
                % Add the property as a parameter to the parser scheme
                addParameter(this, TmpMpr.Name, opt_vars{:});
            end
        end
              
        % parse varargin and assign results to class properties 
        % with the same names as parameters 
        function processInputs(this, Obj, varargin)  
            parse(this, varargin{:}); 
            
            % assign results that have associated class properties with
            % public set access
            for i=1:length(this.Parameters)
                par = this.Parameters{i};
                if ~ismember(par, this.UsingDefaults) && isprop(Obj, par)
                    try
                        
                        % The value assignment will fail if the parser does
                        % not have access to the corresponding property;
                        % such properties have to be assigned manually
                        Obj.(par) = this.Results.(par);
                    catch 
                    end 
                end
            end 
        end
    end
end

