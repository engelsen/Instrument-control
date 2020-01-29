function ProgList = getIcPrograms()

    % [run files, instruments, loggers]
    ProgList = MyProgramDescriptor.empty();
    
    RunFiles = readRunFiles();
    
    % Add entries, automatically generated from the InstrumentList
    InstrumentList = getLocalSettings('InstrumentList');
    
    j = 1; % Counter for the program list
    
    for i = 1:length(InstrumentList)
        
        % If a run file for instrument was not specified explicitly and if
        % all the required fields in InstrList are filled, generate a new
        % entry.
        nm = InstrumentList(i).name;
        
        if ~ismember(nm, {RunFiles.name}) && ...
                ~isempty(InstrumentList(i).control_class)
            
            ctrl_class = InstrumentList(i).control_class;
            instr_enabled = InstrumentList(i).enabled;
        
            ProgList(j).name = nm;
            ProgList(j).title = InstrumentList(i).title;
            ProgList(j).type = 'instrument';
            ProgList(j).info = ['% This entry is automatically ' ...
                'generated from InstrumentList'];
            
            ProgList(j).data_source = ismember('NewData', ...
                events(ctrl_class));
            
            ProgList(j).enabled = instr_enabled;
            
            % Command for running the instrument without GUI
            ProgList(j).run_bg_expr = sprintf( ...
                'runInstrument(''%s'', ''enable_gui'', false);', nm);

            % Command for running the instrument with GUI
            ProgList(j).run_expr = sprintf( ...
                'runInstrument(''%s'', ''enable_gui'', true);', nm);

            j = j+1;
        end
        
        % Make default logger name
        nm_logger = [nm 'Logger'];
        
        if ~ismember(nm_logger, {RunFiles.name}) && ...
                ismethod(ctrl_class, 'createLogger') && instr_enabled
            
            % Add an entry for starting a logger with this instrument
            ProgList(j).name = nm_logger;
            ProgList(j).type = 'logger';
            ProgList(j).info = ['% This entry is automatically ' ...
                'generated from InstrumentList'];
            ProgList(j).data_source = true;
            
            try
                
                % Assign logger options found in InstrumentList
                for opt_nm = fieldnames(InstrumentList(i).LoggerOpts)'
                    if isprop(ProgList, opt_nm{1})
                        ProgList(j).(opt_nm{1}) = ...
                            InstrumentList(i).LoggerOpts.(opt_nm{1});
                    end
                end
            catch 
            end  
            
            ProgList(j).run_expr = ['runLogger(''' nm ''');'];
            
            j = j+1;
        end
    end
    
    ProgList = [RunFiles, ProgList];
end

%% Subroutines

% Read all the files which names start from 'run' from the local base
% directory and add entries, automatically generated from InstrumentList
function RunFiles = readRunFiles(dir)
    if ~exist('dir', 'var')
        
        % Search in the local base directory if directory name is not
        % supplied explicitly
        dir = getLocalBaseDir();
    end
            
    % Find all the names of .m files that start with 'run'
    all_names = what(dir);
    is_run = startsWith(all_names.m, 'run', 'IgnoreCase', false);
    run_names = all_names.m(is_run);
    
    RunFiles = MyProgramDescriptor.empty();
    
    % Read headers of all the run*.m files
    for i = 1:length(run_names)
        RunFiles(i).type = 'runfile';
        
        name_tok = regexp(run_names{i}, 'run(.*)\.m', 'tokens');
        
        % Add information about the file name
        RunFiles(i).name = name_tok{1}{1};
        
        % By default title is the same as name
        RunFiles(i).title = RunFiles(i).name;
        
        % Make an expression that needs to be evaluated to run the program. 
        % (just the name of file by default)   
        [~, run_name, ~] = fileparts(run_names{i});
        RunFiles(i).run_expr = run_name;
        
        % Read the run file comment header and assign the parameters found
        Content = readCommentHeader(fullfile(dir, run_names{i}));
        
        RunFiles(i).info = Content.comment_header;
        
        par_names = fieldnames(Content.ParamList);
        for j = 1:length(par_names)
            fn = par_names{j};
            if isprop(RunFiles, fn)
                RunFiles(i).(fn) = Content.ParamList.(fn);
            end
        end
    end
end
