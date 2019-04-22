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
            Fig = findfigure(Gui);
            Fig.Visible = 'off';
            Fig.Visible = 'on';
        catch
        end
    else
        
        % Start GuiLogger in dummy mode
        GuiLw = GuiLogger();
        addInstrument(Collector, name, GuiLw.Lg);
        addInstrumentGui(Collector, name, GuiLw);
        
        % Display the instrument's name 
        Fig = findfigure(GuiLw);
        Fig.Name = char(name);
    end
end

