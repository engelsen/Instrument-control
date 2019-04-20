% Generate a unique file name based on the full file name supplied as the
% input by appending _n with sufficiently large n. 
% This function does not make sure that the filename is valid - i.e. that 
% it does not contain symbols forbidden by the file system.

function [file_name, is_mod] = makeUniqueFileName(file_name)
    [path, name, ext] = fileparts(file_name);
    
    if isempty(name)
        name = 'placeholder';
    end
    
    if isempty(path)
        path = pwd();
    end
    
    % List all the existing files in the measurement directory
    % that have the same extension as our input file name
    DirCont = dir(fullfile(path, ['*', ext]));
    file_ind = ~[DirCont.isdir];
    existing_fns = {DirCont(file_ind).name};

    % Remove extensions
    [~, existing_fns, ~] = cellfun(@fileparts, existing_fns, ...
        'UniformOutput', false);

    % Generate a new file name
    [name, is_mod] = matlab.lang.makeUniqueStrings(name, existing_fns);
    
    file_name = fullfile(path, [name, ext]); 
end

