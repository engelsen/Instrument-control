function path = createSessionPath(base_dir, session_name)
    % The function creates a path of the format 
    %'base_dir\yyyy-mm-dd session_name'

    path = fullfile(base_dir,[datestr(now,'yyyy-mm-dd '), session_name]);
    %Adds the \ at the end if it was not added by the user.
    if ~strcmp(path(end),filesep)
        path(end+1) = filesep;
    end
end

