% menu_title=Spectrum Analyser RSA5103
% show_in_daq=true
function instance_name = runRSA5103()
    instance_name = 'GuiRsaRSA5103';
    if ~isValidBaseVar(instance_name)
        gui = GuiRsa('instr_list', 'RSA5103', 'instance_name', instance_name);
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
