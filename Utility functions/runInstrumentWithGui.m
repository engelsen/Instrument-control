% Create an instrument instance with gui add them to the collector

function [Instr, Gui] = runInstrumentWithGui(name, instr_class, gui_name, varargin)

    % Get the unique instance of Collector
    Collector = MyCollector.instance();

    % Run instrument first
    if ~exist('instr_class', 'var') || ~exist('gui', 'var')
        
        % Run instrument without GUI
        Instr = runInstrument(name);
        
        % Load GUI name from InstrumentList
        InstrumentList = getLocalSettings('InstrumentList');
        
        ind = cellfun(@(x)isequal(x, name), {InstrumentList.name});
        
        assert(any(ind), [name ' must correspond to an entry in ' ...
            'InstrumentList.'])
        
        InstrEntry = InstrumentList(ind);
        
        if length(InstrEntry) > 1
            
            % Multiple entries found
            warning(['Multiple InstrumentList entries found with ' ...
                'name ' name]);
            InstrEntry = InstrEntry(1);
        end
        
        gui_name = InstrEntry.gui;
        
        assert(~isempty(gui_name), ['GUI is not specified for ' name]);
    else
        
        % All arguments are supplied explicitly
        Instr = runInstrument(name, instr_class, varargin{:});
    end
    
    % Check if the instrument already has GUI
    Gui = getInstrumentProp(Collector, name, 'Gui');
    if isempty(Gui) || ~isvalid(Gui)
        
        % Run a new GUI and store it in Collector
        Gui = feval(gui_name, Instr);
        setInstrumentProp(Collector, name, 'Gui', Gui);
        
        % Display the instrument's name 
        Fig = findFigure(Gui);
        if ~isempty(Fig)
           Fig.Name = char(name);
        else
           warning('No UIFigure found to assign the name')
        end
        
        % Apply color scheme
        applyLocalColorScheme(Fig);
        
        % Move the app figure to the center of the screen
        centerFigure(Fig);
    else
        
        % Bring the window of existing GUI to the front
        try
            setFocus(Gui);
        catch
        end
    end
end

