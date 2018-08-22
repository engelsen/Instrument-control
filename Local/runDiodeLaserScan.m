%show_in_daq=true
function runDiodeLaserScan()
    if ~isValidBaseVar('Collector')
        runCollector();    
    end
    Collector = evalin('base','Collector');
    
    name='DiodeLaserScan';
    if ~ismember(name, Collector.running_instruments)
        Instr=DiodeLaserScan('Scope','DPO4034_2','Laser','ECDL850He3',...
            'name','DiodeLaserScan');
        addInstrument(Collector, Instr, 'name', name);
    else
        warning('DiodeLaserScan is already running')
    end
end

