% show_in_daq=true
function instance_name = runRSA5106()
    instance_name = 'GuiRsaRSA5106';
    if ~isValidBaseVar(instance_name)
        gui = GuiRsa('instr_list', 'RSA5106', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
        if ~isValidBaseVar('Collector'); runCollector; end 
           evalin('base', ... 
           sprintf('addInstrument(Collector,%s);',instance_name)); 
     else
        warning('%s is already running', instance_name);
     end
end
