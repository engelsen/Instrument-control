% Create an instrument instance with gui add them to the collector

function [Instr, Gui] = runInstrumentWithGui(name, instr_class, gui, varargin)

    % Get the unique instance of Collector
    Collector = MyCollector.instance();

    % Run instrument first
    if nargin==1
        
        % load parameters from InstrumentList
        InstrumentList = getLocalSettings('InstrumentList');
        
        assert(isfield(InstrumentList, name), [name ' must be a field ' ...
            'of InstrumentList.'])
        
        assert(isfield(InstrumentList.(name), 'gui'), ...
            ['InstrumentList entry ' name ' has no ''gui'' field.'])
        
        gui = InstrumentList.(name).gui;
        Instr = runInstrument(name);
    else
        
        % All the arguments are supplied explicitly
        Instr = runInstrument(name, instr_class, varargin{:});
    end
    
    % Check if the instrument already has GUI
    Gui = getInstrumentGui(Collector, name);
    if isempty(Gui)
        
        % Run a new GUI and store it in the collector
        Gui = feval(gui, Instr);
        addInstrumentGui(Collector, name, Gui);
        
        % Display the instrument's name 
        Fig = findfigure(Gui);
        if ~isempty(Fig)
           Fig.Name = char(name);
        else
           warning('No UIFigure found to assign the name')
        end
    else
        
        % Bring the window of existing GUI to the front
        try
            Fig = findfigure(Gui);
            Fig.Visible = 'off';
            Fig.Visible = 'on';
        catch
        end
    end
end

