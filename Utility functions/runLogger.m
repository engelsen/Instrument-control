% Create a logger based on the instrument built-in method

function [Lg, Gui] = runLogger(instr_name)
    Instr = runInstrument(instr_name);
    
    if ismethod(Instr, 'createLogger')
        Lg = createLogger(Instr);
    else
        warning(['A logger is not created as instrument class ''%s'' ' ...
            'does not define ''createLogger'' method.'], class(Instr));
        return
    end
    
    % Make logger name
    name = [instr_name 'Logger'];
    
    % Add logger to the collector so that it can transfer data to Daq
    C = MyCollector.instance();
    addInstrument(C, name, Lg, 'collect_header', false);
    
    % Check if the instrument already has GUI
    Gui = getInstrumentGui(C, name);
    if isempty(Gui)
        
        % Run a new GUI and store it in the collector
        Gui = GuiLogger(Lg);
        addInstrumentGui(C, name, Gui);
        
        % Display the instrument's name 
        Fig = findFigure(Gui);
        if ~isempty(Fig)
           Fig.Name = char(name);
        else
           warning('No UIFigure found to assign the name')
        end
        
        % Apply color scheme
        applyLocalColorScheme(Fig);
    else
        
        % Bring the window of existing GUI to the front
        try
            setFocus(Gui);
        catch
        end
    end
end

