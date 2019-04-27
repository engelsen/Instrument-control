function runSingletonApp(App, global_name)
    if isValidBaseVar(global_name)
        disp([global_name ' already exists']);
        
        Fig = findFigure(App);
        close(Fig);
        
        % Make sure the new instance is deleted
        delete(App);
        
        App = evalin('base', global_name);
        
        % Bring to the focus the figure of existing app
        setFocus(App);
    else
        assignin('base', global_name, App);
    end
    
    try
        
        % Recolor app according to the present color scheme
        colorSchemeFcn = getLocalSettings('colorSchemeFcn');
        if ~isempty(colorSchemeFcn)
            colorSchemeFcn(App);
        end
    catch
    end
end

