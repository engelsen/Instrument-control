% run instrument instance with gui and add it to the collector
function [Instr, GuiInstr] = runInstrumentWithGui(name, instr_class, interface, address, gui)
    Collector=getCollector();
    
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
        
        Instr = feval(instr_class, interface, address, 'name', name);
        addInstrument(Collector, Instr, 'name', name);
    else
        % If instrument is already present in the Collector, do not create
        % a new object, but try taking the existing one.
        disp([name,' is already running. Assign existing instrument ',...
            'instead of running a new one.']);
        try
            Instr = Collector.InstrList.(name);
        catch
            % Return with empty results in the case of falure
            warning('Could not assign instrument %s from Collector',name);
            Instr = [];
            GuiInstr =[];
            return
        end
    end
    
    % Next turn to gui
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

