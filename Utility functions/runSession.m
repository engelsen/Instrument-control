% Load metadata specified in filename, run all the instruments indicated in
% it and configure the settings of those instruments from metadata
% parameters

function runSession(filename)
    Mdt = MyMetadata.load(filename);
    
    assert(~isempty(Mdt), ['Metadata is not found in the file ''' ...
        filename '''.']);
    
    disp(['Loading session info from file ' filename '...'])
    
    % SessionInfo contains information about the state of Collector
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
        ind = cellfun(@(x)ismember(x, CollMdt.ParamList.instruments), ...
            prog_names);
    else
        
        % Get the list of instruments as the titles of those metadata 
        % entries that have a corresponding local measurement routine
        ind = cellfun(@(x)ismember(x, {Mdt.title}), prog_names);
    end
    
    ActiveProgList = ProgList(ind);
    
    % Delete all the instruments present in the collector
    C = MyCollector.instance();
    
    disp('Closing the current session...')
    
    flush(C);
    
    % Run new instruments and configure their settings
    for i = 1:length(ActiveProgList)
        nm = ActiveProgList(i).name;
        
        disp(['Starting ' nm '...'])
        
        % Extract instument options from the collector metadata or assign
        % default values     
        try
            has_gui = CollMdt.ParamList.InstrProps.(nm).has_gui;
        catch
            has_gui = true;
        end
        
        try 
            gui_position = CollMdt.ParamList.InstrProps.(nm).gui_position;
        catch
            gui_position = '';
        end
        
        % We hedge the operation of running a new instrument so that the
        % falure of one would not prevent starting the others
        try
            if has_gui
                eval(ActiveProgList(i).run_expr);
                
                if ~isempty(gui_position)
                    Instr = getInstrument(C, nm);
                    Fig = findFigure(Instr);
                    
                    original_units = Fig.Units;
                    Fig.Units = 'pixels';
                    
                    % Set x and y position of GUI figure
                    Fig.Position(1) = gui_position(1);
                    Fig.Position(2) = gui_position(2);
                    
                    % Restore the figure settings
                    Fig.Units = original_units;
                end
            else
                eval(ActiveProgList(i).run_bg_expr);
            end

            % Configure the settings of instrument object
            InstrMdt = titleref(Mdt, nm);
            Instr = getInstrument(C, nm);
            
            if ~isempty(InstrMdt) && ismethod(Instr, 'writeSettings')
                if length(InstrMdt) > 1
                    warning(['Duplicated entries are found for the ' ...
                        'instrument with name ''' nm '''.']);
                    InstrMdt = InstrMdt(1);
                end
                
                try
                    writeSettings(Instr, InstrMdt);
                catch ME
                    warning(['Error while attempting to write serrings '...
                        'to ''' nm ''': ' ME.message])
                end
            end
        catch ME
            warning(['Could not start instrument with name ''' nm ...
                '''. Error: ' ME.message])
        end
    end
    
    if ~isempty(CollMdt)
        
        % Set measurement session name
        if isfield(CollMdt.ParamList, 'session_name')
            C.session_name = CollMdt.ParamList.session_name;
        end
        
        % Run apps
        for i = 1:length(CollMdt.ParamList.apps)
            try
                nm = CollMdt.ParamList.apps{i};

                % The convention is such that apps can be instantiated 
                % as classname(), i.e. that their constructor does not have 
                % required input arguments.
                App = eval(CollMdt.ParamList.AppProps.(nm).class);

                pos = CollMdt.ParamList.AppProps.(nm).position;
                if ~isempty(pos)
                    Fig = findFigure(App);

                    original_units = Fig.Units;
                    Fig.Units = 'pixels';

                    % Set x and y position of figure
                    Fig.Position(1) = pos(1);
                    Fig.Position(2) = pos(2);

                    % Restore the figure settings
                    Fig.Units = original_units;
                end
            catch ME
                warning(['Error while attempting to run an app: ' ...
                    ME.message])
            end
        end
    end
    
    disp('Finished loading session.')
end

