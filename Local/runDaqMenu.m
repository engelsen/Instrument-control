function instance_name=runDaqMenu()
    instance_name = 'DaqMenu';
    if ~isValidBaseVar(instance_name)
        gui = DataAcquisitionMenu();
        assignin('base', instance_name, gui);
    else
        warning('%s is already running', instance_name);
    end
end
