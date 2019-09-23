% Start a logger gui in dummy mode, which allows to browse existing logs,
% and add it to the collector as an app.

function runLogViewer()
    name = 'ViewerLogger';
    
    Collector = MyCollector.instance();
    
    if ismember(name, Collector.running_instruments)
        
        % If LogViewer is already present in the Collector, do not create
        % a new one, but rather bring focus to the existing one.
        disp([name, ' is already running.']);
        
        Lg = getInstrument(Collector, name);
        
        % Bring the window of existing GUI to the front
        try
            setFocus(findFigure(Lg.Gui));
        catch ME
            warning(ME.message)
        end
    else
        
        % Start GuiLogger in dummy mode
        Lw = GuiLogger();
        Lw.Lg.Gui = Lw;
        addInstrument(Collector, name, Lw.Lg, 'collect_header', false);
        
        % Display the instrument's name 
        Fig = findFigure(Lw);
        Fig.Name = char(name);
        
        % Apply color scheme
        applyLocalColorScheme(Fig);
        
        % Move the app figure to the center of the screen
        centerFigure(Fig);
    end
end

