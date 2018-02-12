% Save local settings
function setLocalSettings(varargin)
    dir_name = getLocalBaseDir();
    % Settings to be saved need to be specified as 'parameter','value' 
    % pairs in varargin 
    file_name = fullfile(dir_name, 'LocalInstrumentControlSettings.mat');
    SaveList=struct();
    for i=1:floor(length(varargin)/2)
        if isvarname(varargin{2*i-1})
            SaveList.(varargin{2*i-1})=varargin{2*i};
        else
            warning('Setting is not saved as it is not a valid variable name:');
            disp(varargin{2*i-1});
        end
    end
    % Append parameters to the settings file
    save(file_name,'-struct','SaveList','-append');
end

