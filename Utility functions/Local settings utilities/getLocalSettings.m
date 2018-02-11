% Load local settings
function Settings = getLocalSettings(varargin)
    try 
        Settings = load('LocalInstrumentControlSettings.mat');
    catch
        error(['The local settings file is not found. Add the folder, '...
            'containing an existing file to the Matlab path or create '...
            'a new one by runnign Setup.']);
    end
    % If a property is specified as varargin{1}, return it directly 
    if ~isempty(varargin)
        try
            Settings = Settings.(varargin{1});
        catch
            error('No such parameter as %s among the loaded settings',...
                varargin{1});
        end
    end
end

