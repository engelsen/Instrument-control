function ProgList = getIcPrograms()

    % [run files, instruments, loggers]
    ProgList = MyProgramDescriptor.empty;
    
    RunFiles = readRunFiles();
    
    % Add entries, automatically generated from the InstrumentList
    InstrumentList = getLocalSettings('InstrumentList');
    instr_names = fieldnames(InstrumentList);
    
    j = 1; % Counter for the program list
    
    for i = 1:length(instr_names)
        
        % If a run file for instrument was not specified explicitly and if
        % all the required fields in InstrList are filled, generate a new
        % entry.
        nm = instr_names{i};
        
        if ~ismember(nm, {RunFiles.name}) && ...
                ~isempty(InstrumentList.(nm).control_class)
            
            ctrl_class = InstrumentList.(nm).control_class;
        
            ProgList(j).name = nm;
            ProgList(j).type = 'instrument';
            ProgList(j).info = ['% This entry is automatically ' ...
                'generated from InstrumentList'];
            
            ProgList(j).data_source = ismember('NewData', ...
                events(ctrl_class));
            
            try
                ProgList(j).enabled = InstrumentList.(nm).enable;
            catch
                ProgList(j).enabled = true;
            end  

            ProgList(j).run_bg_expr = sprintf('runInstrument(''%s'');',nm);

            if ~isempty(InstrumentList.(nm).gui)

                % Add command for running the instrument with gui
                ProgList(j).run_expr = ...
                    sprintf('runInstrumentWithGui(''%s'');', nm);
            end

            j = j+1;
        end
        
        nm_logger = [nm 'Logger'];
        
        if ~ismember(nm_logger, {RunFiles.name}) && ...
                ismethod(ctrl_class, 'createLogger')
            
            % Add entry for starting a logger with this instrument
            ProgList(j).name = nm_logger;
            ProgList(j).type = 'logger';
            ProgList(j).info = ['% This entry is automatically ' ...
                'generated from InstrumentList'];
            ProgList(j).data_source = true;
            
            try
                
                % Assign logger options found in InstrumentList
                logger_opts = fieldnames(InstrumentList.(nm).LoggerOpts);
                
                for k = 1:length(logger_opts)
                    opt_nm = logger_opts{k};
                    if isprop(ProgList, opt_nm)
                        ProgList(j).(opt_nm) = ...
                            InstrumentList.(nm).LoggerOpts.(opt_nm);
                    end
                end
            catch 
            end  
            
            ProgList(j).run_expr = ['runLogger(' nm ');'];
            
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
    
    RunFiles = MyProgramDescriptor.empty;
    
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
        ParamList = readCommentHeader(fullfile(dir, run_names{i}));
        
        RunFiles(i).info = ParamList.comment_header;
        
        for fn = fieldnames(ParamList)'
            if isprop(RunFiles, fn)
                RunFiles(i).(fn) = ParamList.(fn);
            end
        end
    end
end
