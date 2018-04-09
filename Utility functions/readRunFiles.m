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
        fname = fullfile(dir, run_names{i});
        % Read the run file comment header
        run_files.(nm) = readCommentHeader(fname);
        if isfield(run_files.(nm),'show_in_daq')
            run_files.(nm).show_in_daq = eval(...
                lower(run_files.(nm).show_in_daq));
        end
        % Add information about file name
        run_files.(nm).name = nm;
        run_files.(nm).fullname = fname;
    end
end
