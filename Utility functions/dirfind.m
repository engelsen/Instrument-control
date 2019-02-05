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
    
    % Search in .m (functions and classes) and .mlapp (Matlab apps) files 
    code_file_names = DirContent.m;
    app_file_names = DirContent.mlapp;
    
    % Go over the .m files using a local subroutine
    file_names=filterFiles(fullfile(dir_name, code_file_names), str);
    
    % Go over the.mlapp files. Each Matlab app file needs to be unzipped 
    % before its content can be parsed. Use a temporary forder in 'C:\Temp' 
    % for this purpose.
    tmp_dir=fullfile('C:','Temp','Matlab Instrument Control dirfind');
    if exist(tmp_dir,'dir')~=7
        mkdir(tmp_dir)
    end
    
    for i=1:length(app_file_names)
        fn=fullfile(dir_name, app_file_names{i});
        % For convenience, make a sub-directory named the same as the app
        sd=fullfile(tmp_dir, app_file_names{i});
        unzip(fn, sd);
        % Search over the unzipped files directory
        unzipped_file_names=listDirFiles(sd);
        
        res=filterFiles(unzipped_file_names, str);
        % If the unzipped content contains the string we are looking for,
        % add the app name to the output list
        if ~isempty(res)
            file_names=[file_names; fn]; %#ok<AGROW>
        end
        
        % Clean up - delete the temporary subdirectory
        rmdir(sd, 's');
    end
    
    % Delete the temporary directory
    rmdir(tmp_dir, 's');
    
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

%% Local functions not visible from outside

% Returns the names of all the files present in the directory, 
% recursively running over subforders 
function file_names=listDirFiles(dir_name)
    DirContent=dir(dir_name);
    all_names=fullfile(dir_name,{DirContent.name});
    % Make column
    all_names=all_names(:);
    sub_dir_ind=arrayfun(@(x)(x.isdir && ~strcmp(x.name,'.') && ...
        ~strcmp(x.name,'..')), DirContent);
    file_ind=~[DirContent.isdir];
    
    dir_names=all_names(sub_dir_ind);
    file_names=all_names(file_ind);

    % Iterate over subdirectories
    for i=1:length(dir_names)
        file_names=[file_names; listDirFiles(dir_names{i})]; %#ok<AGROW>
    end
end

% Select those files from file_list that contain string 'str'
function file_names=filterFiles(file_list, str)
    file_names={};
    for i=1:length(file_list)
        fn=file_list{i};
        try
            content=fileread(fn);
        catch
            warning('Could not read the content of file %s', fn)
            continue
        end
        
        if contains(content, str)
            % Append to the output list
            file_names=[file_names; {fn}]; %#ok<AGROW>
        end
    end
end
