% Inverse function to createSessionPath - it splits path into base
% directory and session name

function [base_dir, session_name] = splitSessionPath(path)
    path_split = split(path, filesep());
    
    if length(path_split) > 1
        base_dir = fullfile(path_split{1:end-1});
    else
        base_dir = '';
    end
    
    % Remove date from the session name
    session_name_tok = regexp(path_split{end}, ...
        '\d\d\d\d-\d\d-\d\d (.*)', 'tokens');
    
    if ~isempty(session_name_tok)
        session_name = session_name_tok{1}{1};
    else
        session_name = path_split{end};
    end
end

