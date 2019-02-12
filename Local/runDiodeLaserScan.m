%show_in_daq=true
function runDiodeLaserScan()
    % Get the unique instance of MyCollector
    C = MyCollector.instance();
    
    name='DiodeLaserScan';
    if ~ismember(name, C.running_instruments)
        % Create an instrument instance
        Instr=DiodeLaserScan('Scope','DPO4034_2','Laser','ECDL850He3',...
            'name','DiodeLaserScan');
        % Add instrument to Collector
        addInstrument(C, Instr);
    else
        warning('DiodeLaserScan is already running')
    end
end

