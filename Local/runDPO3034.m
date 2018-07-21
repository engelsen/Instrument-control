% show_in_daq=true
function instance_name = runDPO3034()
    instance_name = 'GuiScopeDPO3034';
    if ~isValidBaseVar(instance_name)
        gui = GuiScope('instr_list', 'DPO3034', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
        if ~isValidBaseVar('Collector'); runCollector; end
        evalin('base', ...
            sprintf('addInstrument(Collector,findMyInstrument(%s))',...
            instance_name));
    else
        warning('%s is already running', instance_name);
    end
end
