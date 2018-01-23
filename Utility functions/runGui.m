function runGui(instr_name, gui_name)
    % load the InstrAddressList structure
    load('InstrAddressList.mat','InstrAddressList')
    
    % Find out if Gui is running already
    name_exist = ~exist(instr_name, 'var');
    if name_exist
        try
            gui_running = evalin('base',sprintf('isvalid(%s)',instr_name));
        catch
            gui_running = false;
        end
    else
        gui_running = false;
    end
    
    % Start the instrument Gui if not running already
    if ~gui_running
        eval_str = sprintf(...
            '%s=%s(''constructor'',InstrAddressList.%s,''name'',''%s'');',...
            instr_name, gui_name, instr_name, instr_name);
        % Evaluate in the Matlab base workspace to create a variable named
        % instr_name
        evalin('base', eval_str);
    else
        warning('GUI for the instrument %s is already running', instr_name);
    end
end

