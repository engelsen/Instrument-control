% Load metadata specified in filename, run all the instruments indicated in
% it and configure the settings of those instruments from metadata
% parameters

function runSession(filename)
    Mdt = MyMetadata.load(filename);
    
    assert(~isempty(Mdt), ['Metadata is not found in the file ''' ...
        filename '''.']);
    
    % SessionInfo contains information about the state of collector
    CollMdt = titleref(Mdt, 'SessionInfo');
    
    if length(CollMdt)>1
        warning(['Multiple SessionInfo fields are found in the file ' ...
            'metadata.']);
        CollMdt = CollMdt(1);
    end
    
    if ~isempty(CollMdt)
        
        % Get the list of instruments active during the session from the
        % collector metadata
        instr_names = CollMdt.ParamList.instruments;
    else
        
        % Get the list of instruments as the titles of those fileds which
        % have a corresponding entry the list of local measurement routines
        ProgList = getIcPrograms();
        prog_names = {ProgList.name};
        
        ind = cellfun(@(x)ismember(x, prog_names), {Mdt.title});
        instr_names = prog_names(ind);
    end
    
    % Delete all the instruments present in the collector
    C = MyCollector.instance();
    flush(C);
    
    % Run new instruments and configure their settings
    for i = 1:length(instr_names)
        nm = instr_names{i};
        
        if ~isempty(CollMdt)
            
            % Extract instument options from the collector metadata
            collect_header = CollMdt.ParamList.Props.(nm).collect_header;
            has_gui = CollMdt.ParamList.Props.(nm).has_gui;
            is_logger = 
        else
            
            % Assign default values for the instrument options
            collect_header = true;
            has_gui = true;
            is_global = true;
            is_logger = false;
        end
        
        % We hedge the operation of running a new instrument so that the
        % falure of one would not prevent starting the others
        try
            if has_gui
                Instr = runInstrumentWithGui(nm);
            else
                Instr = runInstrument(nm);
            end

            C.InstrProps.(nm).collect_header = collect_header;

            InstrMdt = titleref(Mdt, nm);
            if ~isempty(InstrMdt) && ismethod(Instr, 'writeSettings')
                if length(InstrMdt) > 1
                    warning(['Duplicated entries are found for the ' ...
                        'instrument with name ''' nm '''.']);
                    InstrMdt = InstrMdt(1);
                end

                writeSettings(Instr, InstrMdt);
            end
        catch ME
            warning(['Could not start instrument with name ''' nm ...
                '''. Error: ' ME.message])
        end
    end
end

