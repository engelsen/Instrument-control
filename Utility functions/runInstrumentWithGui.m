% run instrument instance with its gui and add it to the collector
function runInstrumentWithGui(instr_class, interface, address, name, gui)
    if ~isValidBaseVar('Collector')
        runCollector();    
    end
    Collector = evalin('base','Collector');
    
    if ~ismember(name, Collector.running_instruments)
        Instr = feval(instr_class, interface, address);
        GuiInstr = feval(gui, 'Instr', Instr, 'name', ['Gui',name]);
        addInstrument(Collector, GuiInstr, 'name', name); 
       
        % Display instrument's name if given
        fig_handle=findfigure(GuiInstr);
        if ~isempty(fig_handle)
           fig_handle.Name=char(name);
        else
           warning('No UIFigure found to assign the name')
        end
     else
        warning('%s is already running', name);
    end
end

