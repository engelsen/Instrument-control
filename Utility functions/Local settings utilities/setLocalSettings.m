% Save local settings provided as name-value pairs

function setLocalSettings(varargin)

    % Use an input parser with no parameters to ensure the proper
    % formatting of name-value pairs
    p = inputParser();
    p.KeepUnmatched = true;
    parse(p, varargin{:});
    
    SaveList = p.Unmatched;

    % Get the full name of file containing local settings
    dir_name = getLocalBaseDir();
    file_name = fullfile(dir_name, 'LocalInstrumentControlSettings.mat');
    
    % Save the fields of structure SaveList as individual variables and
    % overwrite if a variable already exists.
    save(file_name, '-struct', 'SaveList', '-append');
end

