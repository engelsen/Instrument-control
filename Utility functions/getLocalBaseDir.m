% Reurn the directory name, where the local instrument control settings 
% file is located
function dir = getLocalBaseDir()
    % Dir is defined as the directory containing LocalInstrumentControlSettings
    [dir,~,~] = fileparts(which('LocalInstrumentControlSettings.mat'));
    if isempty(dir)
        error(['The local settings file is not found. Add the folder, '...
            'containing an existing file to the Matlab path or create '...
            'a new one by runnign Setup.']);
    end
end

