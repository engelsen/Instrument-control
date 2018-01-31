% Return the loaded computer-specific variable InstrumentList from the
% local base directory
function InstrumentList = getLocalInstrList()
    file_name = fullfile(getLocalBaseDir(),'InstrumentList.mat');
    load(file_name,'InstrumentList');
end

