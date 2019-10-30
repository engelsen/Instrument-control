function runSingletonApp(App, varargin)
    
    C = MyCollector.instance();
    
    % Singleton apps can be uniquely identified by the name of their class
    name = class(App);

    if ismember(name, C.running_apps)
        Fig = findFigure(App);
        close(Fig);
        
        % Make sure the new instance is deleted
        delete(App);
        App = getApp(C, name);
        
        % Bring to the focus the figure of existing app
        setFocus(App);
        
        error([name ' already exists']);
    else
        addApp(C, App, name); 
        
        % Recolor app according to the present color scheme
        applyLocalColorScheme(App);
        
        % Move the app figure to the center of the screen
        centerFigure(App);
    end
end