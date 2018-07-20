% show_in_daq=true
function instance_name = runTDS2022()
    instance_name = 'GuiScopeTDS2022';
    if ~isValidBaseVar(instance_name)
        gui = GuiScope('instr_list', 'TDS2022', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
        if ~isValidBaseVar('DaqMenu'); runDaqMenu; end 
           evalin('base', ... 
           sprintf('addInstrument(DaqMenu.Collector,findMyInstrument(%s))',... 
           instance_name)); 
     else
        warning('%s is already running', instance_name);
     end
end
