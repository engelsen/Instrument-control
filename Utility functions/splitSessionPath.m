% Inverse function to createSessionPath - it splits path into base
% directory and session name

function [base_dir, session_name] = splitSessionPath(path)
    if isempty(path)
        base_dir = '';
        session_name = '';
    end
    
    % Remove file separator from the end if present
    if isequal(path(end), filesep())
        path = path(1:end-1);
    end
    
    path_split = split(path, filesep());
    
    % Remove date from the session name
    session_name_tok = regexp(path_split{end}, ...
        '\d\d\d\d-\d\d-\d\d (.*)', 'tokens');
    
    if ~isempty(session_name_tok)
        session_name = session_name_tok{1}{1};
        base_dir = fullfile(path_split{1:end-1});
    else
        
        % Treat the entire path as base directory
        session_name = '';
        base_dir = fullfile(path_split{1:end});
    end
end

