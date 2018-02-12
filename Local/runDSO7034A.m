% menu_title=Agilent DSO7034A
% show_in_daq=true
function instance_name = runDSO7034A()
    instance_name = 'GuiScopeDSO7034A';
    if ~isValidBaseVar(instance_name)
        gui = GuiScope('instr_list', 'DSO7034A', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
