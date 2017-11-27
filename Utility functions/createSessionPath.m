function path = createSessionPath(base_dir, session_name)
% The function creates a path of the format 
%'base_dir\yyyy-mm-dd session_name'

%Adds the \ at the end if it was not added by the user.
if ~strcmp(base_dir(end),'\')
    bd = [base_dir,'\'];
end
if ~strcmp(session_name(end),'\')
    sn = [session_name,'\'];
end
path = [bd,datestr(now,'yyyy-mm-dd '), sn];
end

