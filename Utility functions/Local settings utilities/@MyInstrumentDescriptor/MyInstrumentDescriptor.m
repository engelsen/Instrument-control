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
         % If title is not specified, return name
         function val = get.title(this)
             if isempty(this.title)
                 val = this.name;
             else
                 val = this.title;
             end
         end
         
         function this = set.name(this, val)
             assert(isvarname(val), ['Value assigned to ''name'' must ' ...
                 'be a valid MATLAB variable name.'])
             this.name = val;
         end
         
         function this = set.enabled(this, val)
             
             % Attempt convertion to logical
             val = logical(val);
             
             assert(islogical(val) && isscalar(val), ['Value assigned ' ...
                 'to ''enabled'' must be a logical scalar.']);
             this.enabled = val;
         end
         
         function this = set.StartupOpts(this, val)
             assert(isstruct(val), ['Value assigned to ''StartupOpts'''...
                 ' must be a structure.'])
             this.StartupOpts = val;
         end
         
         function Val = get.LoggerOpts(this)
             Val = this.LoggerOpts;
             
             if ~isfield(Val, 'enabled')
                 Val.enabled = ismethod(this.control_class, ...
                     'createLogger') && this.enabled;
             end
         end
         
         function this = set.LoggerOpts(this, val)
             assert(isstruct(val), ['Value assigned to ''LoggerOpts''' ...
                 ' must be a structure.'])
             this.LoggerOpts = val;
         end
     end
end

