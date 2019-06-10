% Create instrument instance and add it to the collector

function Instr = runInstrument(name, instr_class, varargin)
    
    % Get the unique instance of Collector
    Collector = MyCollector.instance();
    
    % Check if the instrument is already running
    if ismember(name, Collector.running_instruments)
        
        % If instrument is already present in the Collector, do not create
        % a new object, but try taking the existing one.
        disp([name, ' is already running. Assigning the existing ', ...
            'object instead of running a new one.']);
        
        Instr = getInstrument(Collector, name);
        return
    end
    
    % Create a new instrument object 
    if ~exist('instr_class', 'var')

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
        
        instr_args = struct2namevalue(InstrEntry.StartupOpts);
    else
        
        % Case when all the arguments are supplied explicitly
        instr_args = varargin;
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
        if ismethod(Instr, 'sync')
            sync(Instr);
        end
        
        % Send identification request to the instrument
        if ismethod(Instr, 'idn')
            idn(Instr);
        end
    catch ME
        warning(['Could not start communication with ' name ...
            '. Error: ' ME.message]);
    end
end

