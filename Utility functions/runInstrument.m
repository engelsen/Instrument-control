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
        
        try
            Instr = Collector.InstrList.(name);
        catch
            error('Could not assign instrument %s from Collector',name);
        end
        
        return
    end
    
    % Create a new instrument object 
    if nargin()==1

        % Load instr_class, interface, address and other startup arguments 
        % from InstrumentList
        InstrumentList = getLocalSettings('InstrumentList');
        
        assert(isfield(InstrumentList, name), [name ' must be a field ' ...
            'of InstrumentList.'])
        
        assert(isfield(InstrumentList.(name), 'control_class'), ...
            ['InstrumentList entry ' name ...
            ' has no ''control_class'' field.'])
        
        instr_class = InstrumentList.(name).control_class;
        
        instr_args = {}; % instrument startup arguments
        
        if isfield(InstrumentList.(name), 'interface')
            instr_args = [instr_args, {'interface', ...
                InstrumentList.(name).interface}];
        end
        
        if isfield(InstrumentList.(name), 'address')
            instr_args = [instr_args, {'address', ...
                InstrumentList.(name).address}];
        end

        % Make a list of optional name-value pairs. Put the options on the
        % left-hand side of the list so that they could not overshadow
        % 'interface' and 'address'
        if isfield(InstrumentList.(name), 'StartupOpts')
            Opts = InstrumentList.(name).StartupOpts;
            instr_args = [struct2namevalue(Opts), instr_args];
        end
    else
        
        % Case when all the arguments are supplied explicitly
        instr_args = varargin;
    end

    % Create an instrument instance and store it in Collector
    Instr = feval(instr_class, instr_args{:});
    addInstrument(Collector, Instr, 'name', name);
    
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

