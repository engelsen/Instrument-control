% General Plot
function runDaq()
    C = MyCollector.instance();
    
    name = 'Daq';
    
    if ismember(name, C.running_apps)
        App = getApp(C, name);
        
        % Bring to the focus the figure of existing app
        setFocus(App);
    else
        App = MyDaq('collector_handle', C);
        addApp(C, App, name); 
        
        % Recolor app according to the present color scheme
        applyLocalColorScheme(App);
    end
end

