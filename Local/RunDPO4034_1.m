% menu_title=Scope DPO4034-1
% show_in_daq=true
function instance_name = runDPO4034_1()
    instance_name = 'GuiDpoDPO4034_1';
    if ~isValidBaseVar(instance_name)
        gui = GuiDpo('instr_list', 'DPO4034_1', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
