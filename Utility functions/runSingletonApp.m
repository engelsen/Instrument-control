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
        
        % Set up a listener that will clear the global name 
        addlistener(App, 'ObjectBeingDestroyed', @clearGlobalName);
    end
    
    % The declaration of listener callback
    function clearGlobalName(~, ~)
        if ~isempty(global_name)
            try
                evalin('base', sprintf('clear(''%s'');', global_name));
            catch ME
                warning(['Could not clear global variable ''' ...
                    global_name '''. Error: ' ME.message]);
            end
        end
    end
end

