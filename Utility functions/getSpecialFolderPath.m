% Matlab example from 'Read Special System Folder Path' in the manual.
% Slightly modified to throw more meaningful error messages and provide 
% output in char format.

% Returns the special system folders such as "Desktop", "MyMusic" etc.
% arg can be any one of the enum element mentioned in this link
% http://msdn.microsoft.com/en-us/library/
% system.environment.specialfolder.aspx
% e.g. 
%       >> getSpecialFolder('Desktop')
%
%       ans = 
%       C:\Users\jsmith\Desktop
 
% Get the type of SpecialFolder enum, this is a nested enum type.

function result = getSpecialFolderPath(nm)

    SpecialFolderType = System.Type.GetType(...
        'System.Environment+SpecialFolder');
    % Get a list of all SpecialFolder enum values 
    SpecialFolders = System.Enum.GetValues(SpecialFolderType);
    sf_names = cell(SpecialFolders.Length,1);
    
    % SpecialFolders is not an array so cannot unwrap for in arrayfun
    ind=[];
    for i = 1:SpecialFolders.Length
        sf_names{i}=char(SpecialFolders(i));
        if strcmp(sf_names{i},nm)
            ind=i;
            % Do not stop if a match is found in order to make the full 
            % list of folder names
        end
    end

    % Validate
    if isempty(ind)
        error(['Invalid folder name. Special system folder name must ', ...
            'be one of the following:', newline, strjoin(sf_names,'\n')])
    end

    % Call GetFolderPath method and return the result
    result = char(System.Environment.GetFolderPath(SpecialFolders(ind)));
end

