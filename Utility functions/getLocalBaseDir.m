% Reurn the directory name, where the local instrument control files are 
% located
function dir = getLocalBaseDir()
    % Dir is defined as the directory with the InstrumentList
    [dir,~,~] = fileparts(which('InstrumentList.mat'));
    if isempty(dir)
        % The default value in case the InstrumentList is not found
        dir = 'C:\'; 
    end
end

