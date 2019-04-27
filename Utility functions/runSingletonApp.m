function runSingletonApp(App, global_name)
    if isValidBaseVar(global_name)
        Fig = findFigure(App);
        close(Fig);
        
        % Make sure the new instance is deleted
        delete(App);
        App = evalin('base', global_name);
        
        % Bring to the focus the figure of existing app
        setFocus(App);
        
        error([global_name ' already exists']);
    else
        assignin('base', global_name, App);
        
        % Recolor app according to the present color scheme
        applyLocalColorScheme(App);
    end
end

