% Class for storing information about local instruments

classdef MyInstrumentDescriptor
    properties (Access = public)
        name            = ''        % Identifier that is a MATLAB variable name
        title           = ''        % Title displayed in menus
        control_class   = ''        % Instrument control class
        gui             = ''        % Gui
        enabled         = true     
        StartupOpts     = struct()  % Options passed to the class constructor on startup
        LoggerOpts      = struct()  % Options for starting a logger with this instrument
    end
    
    methods (Access = public)
        function this = MyInstrumentDescriptor(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
     end
     
     methods 
         function this = set.name(this, val)
             assert(isvarname(val), '''name'' must be valid variable name')
             this.name = val;
         end
         
         % If title is not specified, return name
         function val = get.title(this)
             if isempty(this.title)
                 val = this.name;
             else
                 val = this.title;
             end
         end
     end
end

