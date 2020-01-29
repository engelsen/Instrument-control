% Load the color scheme from local settings and apply it to Obj

function applyLocalColorScheme(Obj)

    % Having right color scheme is usually not crucial for the 
    % functionality of code, therefore we never throw errors during the 
    % recoloring operation
    try
        
        % Load the color scheme from local settings
        S = getLocalSettings('ColorScheme');
        
        if ~strcmpi(S.name, 'default')
            S.colorSchemeFcn(findFigure(Obj));
        end
    catch 
    end
end

