% Check if the name belongs to a valid object in the global workspace

function bool = isValidBaseVar(name)  
    cmd = sprintf('exist(''%s'', ''var'') && isvalid(%s)', name, name);
    bool = evalin('base', cmd);
end

