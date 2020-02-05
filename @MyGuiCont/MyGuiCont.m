% Class that provides basic functionality for handling App-based GUIs

classdef MyGuiCont < handle
    
    properties (Access = public)
        
        % GUI object that is stored for reference only. Should include the
        % main figure.
        Gui
        
        % Name of the GUI class that can be used with the instrument
        gui_name  char 
    end
    
    methods (Access = public)
        function this = MyGuiCont()
            
            % Create default name of the GUI based on the class name
            class_name = class(this);
            
            % Optionally remove 'My' in front of the class name
            tok = regexp(class_name, '(My)?(.+)','tokens');
            
            try
                if ~isempty(tok)
                    this.gui_name = ['Gui' tok{1}{2}];
                end
            catch ME
                warning(['Could not create default GUI name for ' ...
                    'the class ' class_name '. Error:' ME.message]);
            end
        end
        
        function createGui(this)
            assert(~isempty(this.gui_name), ['GUI name is not ' ...
                'specified for the instrument class ' class(this)]);
            
            if isempty(this.Gui) || ~isvalid(this.Gui)
                this.Gui = feval(this.gui_name, this);
            end
        end
        
        function closeGui(this)
            if isempty(this.Gui) || ~isvalid(this.Gui)
                
                % Do nothing as there is no GUI already
                return
            end
            
            try
                
                % Remove the object from the cleanup list list so it is not 
                % deleted with GUI 
                removeFromCleanup(this.Gui.GuiSync, this)
            catch 
            end
            
            % Delete the app by closing its figure 
            closeApp(this.Gui);
            this.Gui = [];
        end
    end
    
    methods
        function set.Gui(this, Val)
            assert(isempty(Val) || (~isempty(findFigure(Val))), ...
                ['Value assigned to Gui property must include a figure '...
                'or be empty.']);
            
            this.Gui = Val;
        end
    end
end

