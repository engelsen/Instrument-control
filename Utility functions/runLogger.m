% Create a logger based on the instrument built-in method

function [Lg, Gui] = runLogger(instr_name)
    Instr = runInstrument(instr_name);
    
    % Make logger name
    name = [instr_name 'Logger'];
    
    % Add logger to the collector so that it can transfer data to Daq
    C = MyCollector.instance();
    
    if ~isrunning(C, name)
        
        % Create and set up a new logger
        if ismethod(Instr, 'createLogger')
            try
                dir = getLocalSettings('default_log_dir');
            catch
                try
                    dir = getLocalSettings('measurement_base_dir');
                    dir = createSessionPath(dir, [instr_name ' log']);
                catch
                    dir = '';
                end
            end

            Lg = createLogger(Instr);

            createLogFileName(Lg, dir, instr_name);
        else
            warning(['A logger is not created as instrument class ' ...
                '''%s'' does not define ''createLogger'' method.'], ...
                class(Instr));
            return
        end
        
        % Add logger to Collector
        addInstrument(C, name, Lg, 'collect_header', false);
    else
        disp(['Logger for ' instr_name ' is already running. ' ...
            'Returning existing.'])
        
        Lg = getInstrument(C, name);
    end
    
    % Check if the logger already has a GUI
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

