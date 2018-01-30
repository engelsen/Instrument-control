% menu_title=Scope DPO3034
% show_in_daq=true
function instance_name = runDPO3034()
    instance_name = 'GuiDpoDPO3034';
    if ~isValidBaseVar(instance_name)
        gui = GuiDpo('instr_list', 'DPO3034', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
