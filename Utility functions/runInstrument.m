% Create instrument instance and add it to the collector

function Instr = runInstrument(name, varargin)

    % Process inputs
    p = inputParser();
    p.KeepUnmatched = true;
    addParameter(p, 'instr_class', '', @ischar);
    addParameter(p, 'enable_gui', false, @islogical);
    parse(p, varargin{:});
    
    instr_class = p.Results.instr_class;
    enable_gui = p.Results.enable_gui;
    un_varargin = struct2namevalue(p.Unmatched);
    
    % Get the unique instance of Collector
    Collector = MyCollector.instance();
    
    % Check if the instrument is already running
    if ismember(name, Collector.running_instruments)
        
        % If instrument is already present in the Collector, do not create
        % a new object, but return the existing one.
        disp([name, ' is already running. Assigning the existing ', ...
            'object instead of creating a new one.']);
        
        Instr = getInstrument(Collector, name);
        
        Fig = findFigure(Instr);
        
        if isempty(Fig) 
            if enable_gui && ismethod(Instr, 'createGui')
            
                % Ensure the instrument has GUI
                createGui(Instr);

                Fig = findFigure(Instr);
                setupFigure(Fig, name);
            end
        else
            
            % Bring the window of existing GUI to the front
            setFocus(Fig);
        end
        
        return
    end
    
    % Create a new instrument object 
    if isempty(instr_class)

        % Load instr_class, interface, address and other startup arguments 
        % from InstrumentList
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
        
        instr_class = InstrEntry.control_class;
        
        assert(~isempty(instr_class), ['Control class is not specified '...
            'for ' name]);
        
        instr_args = [struct2namevalue(InstrEntry.StartupOpts), ...
            un_varargin];
    else
        
        % Case in which all the arguments are supplied explicitly
        instr_args = un_varargin;
    end

    % Create an instrument instance and store it in Collector
    Instr = feval(instr_class, instr_args{:});
    addInstrument(Collector, name, Instr);
    
    try
        
        % Open communication. Typically instrument commands will re-open 
        % the communication object if it is closed, but keepeing it open  
        % speeds communication up.
        if ismethod(Instr, 'openComm')
            openComm(Instr);
        end
        
        % Send identification request to the instrument
        if ismethod(Instr, 'idn')
            idn(Instr);
        end
        
        % Read out the state of the physical device
        if ismethod(Instr, 'sync')
            sync(Instr);
        end
    catch ME
        warning(['Could not start communication with ' name ...
            '. Error: ' ME.message]);
    end
    
    if enable_gui && ismethod(Instr, 'createGui')
            
        % Ensure the instrument has GUI
        createGui(Instr);
    end
    
    Fig = findFigure(Instr);
    
    if ~isempty(Fig)
        setupFigure(Fig, name);
    end
end

function setupFigure(Fig, name)
    try
            
        % Display the instrument's name 
        Fig.Name = char(name);

        % Apply color scheme
        applyLocalColorScheme(Fig);

        % Move the app figure to the center of the screen
        centerFigure(Fig);
    catch ME
        warning(['Error while setting up the GUI of ' name ':' ...
            ME.message]);
    end
end

