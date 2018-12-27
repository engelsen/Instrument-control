% Create instrument instance and add it to the collector

function Instr = runInstrument(name, instr_class, interface, address)
    Collector=getCollector();
    
    if ~ismember(name, Collector.running_instruments)
        if nargin==1
            % load instr_class, interface and address parameters 
            % from InstrumentList
            InstrumentList = getLocalSettings('InstrumentList');
            if ~isfield(InstrumentList, name)
                error('%s is not a field of InstrumentList',...
                    name);
            end
            if ~isfield(InstrumentList.(name), 'interface')
                error(['InstrumentList entry ', name,...
                    ' has no ''interface'' field']);
            else
                interface = InstrumentList.(name).interface;
            end
            if ~isfield(InstrumentList.(name), 'address')
                error(['InstrumentList entry ', name,...
                    ' has no ''address'' field']);
            else
                address = InstrumentList.(name).address;
            end
            if ~isfield(InstrumentList.(name), 'control_class')
                error(['InstrumentList entry ', name,...
                    ' has no ''control_class'' field']);
            else
                instr_class = InstrumentList.(name).control_class;
            end
        elseif nargin==4
            % Case when all the arguments are supplied explicitly, do
            % nothing
        else
            error(['Wrong number of input arguments. ',...
                'Function can be called as f(name) or ',...
                'f(name, instr_class, interface, address).'])
        end
        
        Instr = feval(instr_class, interface, address, 'name', name);
        addInstrument(Collector, Instr, 'name', name);
    else
        % If instrument is already present in the Collector, do not create
        % a new object, but try taking the existing one.
        disp([name,' is already running. Assign existing instrument ',...
            'instead of running a new one.']);
        try
            Instr = Collector.InstrList.(name);
        catch
            % Return with empty results in the case of falure
            warning('Could not assign instrument %s from Collector',name);
            Instr = [];
        end
    end

end

