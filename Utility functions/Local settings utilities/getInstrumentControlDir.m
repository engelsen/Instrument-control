% Identify the folder in which instrument-control package is located 

function ic_dir = getInstrumentControlDir()
    % Presently we identify the package directory as the parent directory
    % of MyInstrument class
    [dir,~,~] = fileparts(which('MyInstrument'));
    dir_parts = regexp(dir, filesep, 'split');
    if ~isempty(dir_parts{end}) && dir_parts{end}(1)=='@'
        ic_dir = fullfile(dir_parts{1:end-1});
    else
        ic_dir = dir;
    end
end

