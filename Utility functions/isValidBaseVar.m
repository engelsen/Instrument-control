% Check if the name belongs to a valid object in the global workspace

function bool = isValidBaseVar(name)  
    try
        var = evalin('base', name);
    catch
        bool = false;
        return
    end
    
    try
        bool = isvalid(var);
    catch

        % If variable exists and isvalid function is not applicable to
        % it, it is still regarded as valid
        bool = true;
    end
end

