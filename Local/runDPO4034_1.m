% menu_title=Tektronix DPO4034_1
% show_in_daq=true
function instance_name = runDPO4034_1()
    instance_name = 'GuiScopeDPO4034_1';
    if ~isValidBaseVar(instance_name)
        gui = GuiScope('instr_list', 'DPO4034_1', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
        if ~isValidBaseVar('Collector'); runCollector; end 
        evalin('base', ... 
           sprintf('addInstrument(Collector,%s)',instance_name)); 
     else
        warning('%s is already running', instance_name);
     end
end
