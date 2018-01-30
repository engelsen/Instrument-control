function run_files = readRunFiles(varargin)
    if ~isempty(varargin) && ischar(varargin{1})
        % The directory to search in can be supplied as varargin{1}
        dir = varargin{1};
    else
        % Otherwise use the local base directory
        dir = getLocalBaseDir();
    end    
    % Find all the names of .m files that start with 'run'
    all_names = what(dir);
    is_run = startsWith(all_names.m,'run','IgnoreCase',false);
    run_names = all_names.m(is_run);
    run_files = struct();
    % Read headers of all the run*.m files
    for i=1:length(run_names)
        name_match = regexp(run_names{i},'run(.*)\.m','tokens');
        nm = name_match{1}{1};
        run_files.(nm) = struct();
        run_files.(nm).name = nm;
        fname = fullfile(dir, run_names{i});
        run_files.(nm).fullname = fname;
        try
            fid = fopen(fname,'r');
            % Read the file line by line, with a paranoid limitation on
            % the number of cycles 
            j = 1;
            header =[];
            while j<100000
                j=j+1;
                str = fgetl(fid);
                trimstr = strtrim(str);
                if isempty(trimstr)
                    % An empty string
                elseif trimstr(1)=='%'
                    % A comment string
                    match = regexp(trimstr,'[%\s]*(.*)=(.*)','tokens');
                    try
                        tag = lower(match{1}{1});
                        run_files.(nm).(tag) = match{1}{2};
                    catch
                    end
                else 
                    % Stop when the code begins
                    break
                end
                % Also store the header in its entirety
                header = [header, str, newline];
            end
            fclose(fid);
            run_files.(nm).header = header;
        catch
            warning('Could not process the run file %s', fname)
        end
    end
end

