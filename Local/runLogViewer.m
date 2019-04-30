% Start a logger gui in dummy mode, which allows to browse existing logs

function runLogViewer()
    name = 'LogViewer';
    
    Collector = MyCollector.instance();
    
    if ismember(name, Collector.running_instruments)
        
        % If LogViewer is already present in the Collector, do not create
        % a new one, but rather bring focus to the existing one.
        disp([name, ' is already running.']);
        
        Gui = getInstrumentGui(Collector, name);
        
        % Bring the window of existing GUI to the front
        try
            setFocus(Gui);
        catch
        end
    else
        
        % Start GuiLogger in dummy mode
        GuiLw = GuiLogger();
        addInstrument(Collector, name, GuiLw.Lg, 'collect_header', false);
        addInstrumentGui(Collector, name, GuiLw);
        
        % Display the instrument's name 
        Fig = findFigure(GuiLw);
        Fig.Name = char(name);
        
        % Apply color scheme
        applyLocalColorScheme(Fig);
        
        % Move the app figure to the center of the screen
        centerFigure(Fig);
    end
end

