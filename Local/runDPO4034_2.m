% menu_title=Scope DPO4034-2
% show_in_daq=true
function instance_name = runDPO4034_2()
    instance_name = 'GuiDpoDPO4034_2';
    if ~isValidBaseVar(instance_name)
        gui = GuiDpo('instr_list', 'DPO4034_2', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
