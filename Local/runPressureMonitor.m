% menu_title=Spectrum Analyser RSA5106
% show_in_daq=false
function instance_name = runPressureMonitor()
    instance_name = 'TPG362';
    if ~isValidBaseVar(instance_name)
        gg=MyTpg('serial','COM4');
        GuiGauge=GuiTpg('Instr',gg);
        assignin('base', instance_name, GuiGauge);
    else
        warning('%s is already running', instance_name);
    end
end
