% Create instrument instance with gui and add it to the collector

function [Instr, GuiInstr] = runInstrumentWithGui(name, instr_class, interface, address, gui)
    % Run instrument
    if nargin==1
        % load parameters from InstrumentList
        InstrumentList = getLocalSettings('InstrumentList');
        if ~isfield(InstrumentList, name)
            error('%s is not a field of InstrumentList',...
                name);
        end
        if ~isfield(InstrumentList.(name), 'gui')
            error(['InstrumentList entry ', name,...
                ' has no ''gui'' field']);
        else
            gui = InstrumentList.(name).gui;
        end
        
        Instr = runInstrument(name);
    elseif nargin==5
        % Case when all the arguments are supplied explicitly
        Instr = runInstrument(name, instr_class, interface, address);
    else
        error(['Wrong number of input arguments. ',...
            'Function can be called as f(name) or ',...
            'f(name, instr_class, interface, address, gui)'])
    end
    
    % Run gui and assign handles to a variable in global workspace
    gui_name = ['Gui',name];
    if ~isValidBaseVar(gui_name)
        % If gui does not present in the base workspace, create it
        GuiInstr = feval(gui, Instr);
        if isprop(GuiInstr,'name')
            GuiInstr.name = gui_name;
        end
        % Store gui handle in a global variable
        assignin('base', GuiInstr.name, GuiInstr);
        % Display instrument's name if given
        fig_handle=findfigure(GuiInstr);
        if ~isempty(fig_handle)
           fig_handle.Name=char(name);
        else
           warning('No UIFigure found to assign the name')
        end
    else
        % Otherwise return gui from base workspace
        GuiInstr = evalin('base',['Gui',name]);
        try
            % bring app figure on top of other windows
            Fig = findfigure(GuiInstr);
            Fig.Visible = 'off';
            Fig.Visible = 'on';
        catch
        end
    end
end

