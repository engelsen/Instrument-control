% Create instrument instance and add it to the collector

function Instr = runInstrument(name, instr_class, interface, address)
    % Get the unique instance of Collector
    Collector=MyCollector.instance();
    
    if ~ismember(name, Collector.running_instruments)
        if nargin()==1
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
            if isfield(InstrumentList.(name), 'StartupOpts')
                % Make a list of optional name-value pairs
                opt_names=fieldnames(InstrumentList.(name).StartupOpts);
                opt_args={};
                for i=1:length(opt_names)
                    opt_args=[opt_args, {opt_names{i}, ...
                        InstrumentList.(name).StartupOpts.(opt_names{i})}]; %#ok<AGROW>
                end
            end
        elseif nargin()==4
            % Case when all the arguments are supplied explicitly, do
            % nothing
            opt_args={};
        else
            error(['Wrong number of input arguments. ',...
                'Function can be called as f(name) or ',...
                'f(name, instr_class, interface, address).'])
        end
        
        % Skip the interface and address arguments if they are empty
        req_args={};
        if ~isempty(interface)
            req_args=[req_args,{interface}];
        end
        if ~isempty(address)
            req_args=[req_args,{address}];
        end
        
        Instr = feval(instr_class, req_args{:}, opt_args{:}, 'name', name);
        addInstrument(Collector, Instr);
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
            return
        end
    end
    
    % Open device. Communication commands will re-open the device if is
    % closed, but keepeing it always open speeds communication up.
    if ismethod(Instr,'openDevice')
        openDevice(Instr);
    end
    % Send identification request to the instrument
    if ismethod(Instr,'idn')
        idn(Instr);
    end

end

