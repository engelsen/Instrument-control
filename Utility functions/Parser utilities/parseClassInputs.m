% Add class properties to the parsing scheme, parse varargin and 
% assign results to class properties with the same names as 
function parseClassInputs(p, Obj, varargin)
    % Add all class properties, which do not present in the parser scheme
    % yet, to the scheme
    addClassPropeties(p, Obj);    
    % parse
    parse(p, varargin{:});  
    % assign results that have associated class properties
    for i=1:length(p.Parameters)
        par = p.Parameters{i};
        if ismember(par, properties(Obj))&&...
                (~ismember(par, p.UsingDefaults))
            Obj.(par) = p.Results.(par);
        end
    end 
end

