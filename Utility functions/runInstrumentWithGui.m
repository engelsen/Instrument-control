% run instrument instance with gui and add it to the collector
function runInstrumentWithGui(name, instr_class, interface, address, gui)
    if ~isValidBaseVar('Collector')
        runCollector();    
    end
    Collector = evalin('base','Collector');
    
    if ~ismember(name, Collector.running_instruments)
        if nargin==1
            % load parameters from InstrumentList
            InstrumentList = getLocalSettings('InstrumentList');
            if ~isfield(InstrumentList, name)
                error('%s is not a field of InstrumentList',...
                    name);
            end
            if ~isfield(InstrumentList.(name), 'interface')
                error(['InstrumentList entry ', name,...
                    ' has no ''interface'' field']);
            else
                interface = InstrumentList.(name).interface;
            end
            if ~isfield(InstrumentList.(name), 'address')
                error(['InstrumentList entry ', name,...
                    ' has no ''address'' field']);
            else
                address = InstrumentList.(name).address;
            end
            if ~isfield(InstrumentList.(name), 'gui')
                error(['InstrumentList entry ', name,...
                    ' has no ''gui'' field']);
            else
                gui = InstrumentList.(name).gui;
            end
            if ~isfield(InstrumentList.(name), 'control_class')
                error(['InstrumentList entry ', name,...
                    ' has no ''control_class'' field']);
            else
                instr_class = InstrumentList.(name).control_class;
            end
        elseif nargin==5
            % Case when all the arguments are supplied explicitly, do
            % nothing
        else
            error(['Wrong number of input arguments. ',...
                'Function can be called as f(name) or ',...
                'f(name, instr_class, interface, address, gui)'])
        end
        
        Instr = feval(instr_class, interface, address);
        GuiInstr = feval(gui, Instr);
        if isprop(GuiInstr,'name')
            GuiInstr.name = ['Gui',name];
        end
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

