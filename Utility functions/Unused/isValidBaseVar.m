function bool = isValidBaseVar(name)
    % Check if the name exists and valid in the global numspace
    name_exist = ~exist(name, 'var');
    if name_exist
        % Check if the variable is a valid object
        try
            bool = evalin('base',sprintf('isvalid(%s)',name));
        catch
            bool = false;
        end
    else
        bool = false;
    end
end

