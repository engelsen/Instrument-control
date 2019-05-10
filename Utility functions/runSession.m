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
    
    ProgList = getIcPrograms();
    prog_names = {ProgList.name};
    
    if ~isempty(CollMdt)
        
        % Get the list of instruments active during the session from the
        % collector metadata
        ind = cellfun(@(x)ismember(x, prog_names), ...
            CollMdt.ParamList.instruments);
    else
        
        % Get the list of instruments as the titles of those metadata 
        % entries that have a corresponding local measurement routine
        ind = cellfun(@(x)ismember(x, prog_names), {Mdt.title});
    end
    
    ActiveProgList = ProgList(ind);
    
    % Delete all the instruments present in the collector
    C = MyCollector.instance();
    flush(C);
    
    % Run new instruments and configure their settings
    for i = 1:length(ActiveProgList)
        nm = ActiveProgList(i).name;
        
        if ~isempty(CollMdt)
            
            % Extract instument options from the collector metadata
            collect_header = CollMdt.ParamList.Props.(nm).collect_header;
            has_gui = CollMdt.ParamList.Props.(nm).has_gui;
        else
            
            % Assign default values for the instrument options
            collect_header = true;
            has_gui = true;
        end
        
        % We hedge the operation of running a new instrument so that the
        % falure of one would not prevent starting the others
        try
            if has_gui
                eval(ActiveProgList(i).run_expr);
            else
                eval(ActiveProgList(i).run_bg_expr);
            end
            
            setInstrumentProp(C, nm, 'collect_header', collect_header);

            % Configure the settings of instrument object
            InstrMdt = titleref(Mdt, nm);
            if ~isempty(InstrMdt) && ismethod(Instr, 'writeSettings')
                if length(InstrMdt) > 1
                    warning(['Duplicated entries are found for the ' ...
                        'instrument with name ''' nm '''.']);
                    InstrMdt = InstrMdt(1);
                end
                
                Instr = getInstrument(C, nm);
                writeSettings(Instr, InstrMdt);
            end
        catch ME
            warning(['Could not start instrument with name ''' nm ...
                '''. Error: ' ME.message])
        end
    end
end

