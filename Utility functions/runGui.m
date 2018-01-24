function runGui(instr_name, gui_name)
    % load the InstrAddressList structure
    load('InstrAddressList.mat','InstrAddressList');
    
    prog_name=[gui_name,'_',instr_name];
    % Find out if the same Gui with the same device is running already
    name_exist = ~exist(prog_name, 'var');
    if name_exist
        try
            prog_running = evalin('base',sprintf('isvalid(%s)',prog_name));
        catch
            prog_running = false;
        end
    else
        prog_running = false;
    end
    
    % Start the instrument Gui if not running already
    if ~prog_running
        % Replacement ' -> '' in the string
        constructor_name = replace(InstrAddressList.(instr_name),...
            '''','''''');
        eval_str = sprintf(...
            '%s=%s(''constructor'',''%s'',''name'',''%s'');',...
            prog_name, gui_name, constructor_name, instr_name);
        % Evaluate in the Matlab base workspace to create a variable named
        % instr_name
        evalin('base', eval_str);
    else
        warning('%s is already running', prog_name);
    end
end

