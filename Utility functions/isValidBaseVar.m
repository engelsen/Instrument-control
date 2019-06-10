% Check if the name belongs to a valid object in the global workspace

function bool = isValidBaseVar(name)  
    cmd = sprintf(['exist(''%s'', ''var'') && ' ...
        '((ismethod(%s, ''isvalid'') && isvalid(%s)) || ' ...
        '~ismethod(%s, ''isvalid''))'], name, name, name, name);
    bool = evalin('base', cmd);
end

