% Load local settings
function Settings = getLocalSettings(varargin)
    try 
        AllSettings = load('LocalInstrumentControlSettings.mat');
    catch
        error(['The local settings file is not found. Add the folder, '...
            'containing an existing file to the Matlab path or create '...
            'a new one by runnign Setup.']);
    end
    
    % If a property is specified as varargin{1}, return it directly 
    if ~isempty(varargin)
        try
            Settings = AllSettings.(varargin{1});
        catch
            error(['No local setting with name ''%s'' found. Existing ' ...
                'settings are the following:\n%s'], varargin{1}, ...
                var2str(fieldnames(AllSettings)));
        end
    else
        
        % Return all settings as a structure
        Settings = AllSettings;
    end
end

