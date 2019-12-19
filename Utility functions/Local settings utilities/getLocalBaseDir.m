% Reurn the directory name, where the local instrument control settings 
% file is located

function dir_name = getLocalBaseDir()

    % Dir is defined as the directory containing 
    % LocalInstrumentControlSettings
    [dir_name,~,~] = fileparts(which('LocalInstrumentControlSettings.mat'));
    
    if isempty(dir_name)
        error(['The local settings file is not found. Add the folder, '...
            'containing an existing file to the Matlab path or create '...
            'a new one by runnign Setup.']);
    end
end

