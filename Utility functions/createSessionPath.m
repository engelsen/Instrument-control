function path = createSessionPath(base_dir, session_name)
% The function creates a path of the format 
%'base_dir\yyyy-mm-dd session_name'

%Adds the \ at the end if it was not added by the user.
if ~strcmp(base_dir(end),'\')
    base_dir(end+1) = '\';
end
if ~strcmp(session_name(end),'\')
    session_name(end+1) = '\';
end
path = [base_dir,datestr(now,'yyyy-mm-dd '), session_name];
end

