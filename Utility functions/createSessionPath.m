function path = createSessionPath(base_dir, session_name)
    % The function creates a path of the format 
    %'base_dir\yyyy-mm-dd session_name'
    
    if nargin() < 2
        
        % Base dir and session name are not suppled explicitly
        base_dir = getLocalSettings('measurement_base_dir');
        C = MyCollector.instance();
        session_name = C.session_name;
    end

    if ~isempty(session_name)
        path = fullfile(base_dir, [datestr(now, 'yyyy-mm-dd '), ...
            session_name]);
    else
        path = base_dir;
    end
    
    % Adds the \ at the end if it was not added by the user.
    if ~strcmp(path(end), filesep)
        path(end+1) = filesep;
    end
end

