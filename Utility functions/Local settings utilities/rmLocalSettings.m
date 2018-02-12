% Remove local settings
function rmLocalSettings(varargin)
    dir_name = getLocalBaseDir();
    % Settings to be saved need to be specified as 'parameter','value' 
    % pairs in varargin 
    file_name = fullfile(dir_name, 'LocalInstrumentControlSettings.mat');
    Settings = load(file_name);
    ind = isfield(Settings, varargin);
    % remove the settings specified in varargin and save the new file
    Settings = rmfield(Settings, varargin(ind));
    save(file_name,'-struct','Settings');
end

