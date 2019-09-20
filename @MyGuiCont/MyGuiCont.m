% Class that provides basic functionality for handling App-based GUIs

classdef MyGuiCont < handle
    
    properties (Access = public)
        
        % GUI object that is stored for reference only
        Gui
        
        % Name of the GUI class that can be used with the instrument
        gui_name  char 
    end
    
    methods (Access = public)
        function createGui(this)
            assert(~isempty(this.gui_name), ['GUI name is not ' ...
                'specified for the instrument class ' class(this)]);
            
            if isempty(this.Gui) || ~isvalid(this.Gui)
                this.Gui = feval(this.gui_name, this);
            end
        end
    end
end

