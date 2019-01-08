% Find occurrences of character string str in all .m files within the given 
% directory.
% The function is useful for tracking code dependences, 
% e.g. the usage of a particular class or method. 

function file_names = dirfind(dir_name, str)
    DirContent = what(dir_name);
    
    if isempty(DirContent)
        file_names={};
        fprintf('Directory %s is empty\n', dir_name);
        return
    end
    
    % Search in .m (functions and classes) and .mappl (Matlab apps) files 
    code_file_names = DirContent.m;
    
    file_names={};
    for i=1:length(code_file_names)
        try
            content=fileread(code_file_names{i});
        catch
            warning('Could not read the content of file %s', ...
                fullfile(dir_name, code_file_names{i}))
            continue
        end
        
        if contains(content, str)
            % Append to the output list
            file_names=[file_names; ...
                {fullfile(dir_name, code_file_names{i})}]; %#ok<AGROW>
        end
    end
    
    % Check all sub-directories, which are not git sub-directories 
    % (starting with '.'), package ('+') or file system symbols ('.', '..')
    DirContent = dir(dir_name);
    all_names = fullfile(dir_name,{DirContent(:).name});
    is_sub_dir = cellfun(...
        @(x) (x(1)~='.' && x(1)~='+' && isfolder(fullfile(dir_name,x))),...
        {DirContent(:).name});
    sub_dir_names = all_names(is_sub_dir);
    
    % Repeat the search in all subfolders
    for i=1:length(sub_dir_names)
        file_names=[file_names; ...
            dirfind(sub_dir_names{i}, str)]; %#ok<AGROW>
    end
end

