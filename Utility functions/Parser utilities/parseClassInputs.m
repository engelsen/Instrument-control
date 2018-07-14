% Add class properties to the parsing scheme, parse varargin and 
% assign results to class properties
function unmatched_varargin = parseClassInputs(p, Object, varargin)
    % Add all class properties, which do not present in the parser scheme
    % yet, to the scheme
    addClassPropeties(p, Object);    
    % parse
    parse(p, varargin{:});  
    % assign results that have associated class properties
    for i=1:length(p.Parameters)
        par = p.Parameters{i};
        if ismember(par, properties(Object))&&...
                (~ismember(par, p.UsingDefaults))
            Object.(par) = p.Results.(par);
        end
    end  
    
    % Put all the Name-Value pairs that were not matched in a new cell
    % array for, possibly, passing it further
    u_pars = fieldnames(p.Unmatched);
    unmatched_varargin = cell(1,2*length(u_pars));
    for i=1:length(u_pars)
        unmatched_varargin{2*i-1} = u_pars{i};
        unmatched_varargin{2*i} = p.Unmatched.(u_pars{i});
    end
end

