% Generic instrument superclass
%
% Undefined/dummy methods:
%   queryString(this, cmd)
% 
% These methods are intentionally not introduced as abstract as under
% some conditions they are not necessary

classdef MyInstrument < dynamicprops & matlab.mixin.CustomDisplay
    
    properties (Access = public)
        
        % Synchronize all properties after setting new value to one
        auto_sync = true
    end
    
    properties (SetAccess = protected, GetAccess = public)
        CommandList = struct()
        
        % identification string
        idn_str = ''
    end
    
    properties (Dependent = true)
        command_names
    end
    
    properties (Access = protected)
        
        % Copying existing metadata is much faster than creating a new one
        Metadata = MyMetadata.empty()
        
        % Logical variables that determine if writing to the instrument 
        % takes place when property is assigned new value
        CommandWriteEnabled = struct()
    end
    
    methods (Access = public)
        function this = MyInstrument(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        % Read all parameters of the physical device
        function sync(this)
            read_ind = structfun(@(x) ~isempty(x.readFcn), ...
                this.CommandList);
            read_cns = this.command_names(read_ind);
            
            for i=1:length(read_cns)
                tag = read_cns{i};
                read_value = this.CommandList.(tag).readFcn();
                
                % Compare to the previous value and update if different.
                % Comparison prevents overhead for objects that listen to 
                % the changes of property values.
                if ~isequal(this.CommandList.(tag).last_value, read_value)
                    
                    % Assign value without writing to the instrument
                    this.CommandWriteEnabled.(tag) = false;
                    this.(tag) = read_value;
                    this.CommandWriteEnabled.(tag) = true;
                end
            end
        end
        
        function addCommand(this, tag, varargin)
            p = inputParser();
            
            % Name of the command
            addRequired(p,'tag', @(x)isvarname(x));
            
            % Functions for reading and writing the property value to the 
            % instrument
            addParameter(p, 'readFcn', function_handle.empty(), ...
                @(x)isa(x, 'function_handle'));
            addParameter(p, 'writeFcn', function_handle.empty(), ...
                @(x)isa(x, 'function_handle'));
            
            % Function applied before writeFcn
            addParameter(p, 'validationFcn', function_handle.empty(), ...
                @(x)isa(x, 'function_handle'));
            
            % Function or list of functions executed after updating the
            % class property value
            addParameter(p, 'postSetFcn', function_handle.empty(), ...
                @(x)isa(x, 'function_handle'));
            
            addParameter(p, 'value_list', {}, @iscell);
            addParameter(p, 'default', 0);
            addParameter(p, 'info', '', @ischar);
            
            parse(p,tag,varargin{:});
            
            assert(~isprop(this, tag), ['Property named ' tag ...
                ' already exists in the class.']);
            
            for fn = fieldnames(p.Results)'
                this.CommandList.(tag).(fn{1}) = p.Results.(fn{1});
            end
            
            this.CommandList.(tag).info = ...
                toSingleLine(this.CommandList.(tag).info);
            
            vl = this.CommandList.(tag).value_list;
            if ~isempty(vl) && isempty(p.Results.validationFcn)
                this.CommandList.(tag).validationFcn = ...
                    createListValidationFcn(this, vl);
            end
            
            % Assign default value from the list if not given explicitly
            if ~isempty(vl) && ismember('default', p.UsingDefaults)
                default = vl{1};
            else
                default = p.Results.default;
            end
            
            % Create and configure a dynamic property
            H = addprop(this, tag);
            H.GetAccess = 'public';
            H.SetObservable = true;
            H.SetMethod = createCommandSetFcn(this, tag);
            
            % Assign the default value with post processing but without
            % writing to the instrument
            this.CommandWriteEnabled.(tag) = false;
            this.(tag) = default;
            this.CommandWriteEnabled.(tag) = true;
            
            if ~isempty(this.CommandList.(tag).writeFcn)
                H.SetAccess = 'public';
            else
                H.SetAccess = {'MyInstrument'};
            end
        end
        
        % Identification
        function [str, msg] = idn(this)
            assert(ismethod(this, 'queryString'), ['The instrument ' ...
                'class must define queryString method in order to ' ...
                'attempt identification.'])
            
            try
                str = queryString(this,'*IDN?');
            catch ME
                str = '';
                msg = ME.message;
            end   
            this.idn_str = str;
        end
        
        % Measurement header
        function Mdt = readSettings(this)
            if isempty(this.Metadata)
                createMetadata(this);
            end
            
            % Ensure that instrument parameters are up to data
            sync(this);
            
            param_names = fieldnames(this.Metadata.ParamList);
            for i = 1:length(param_names)
                tag = param_names{i};
                this.Metadata.ParamList.(tag) = this.(tag);
            end
            
            Mdt = copy(this.Metadata);
        end
        
        % Write settings from structure
        function writeSettings(this, Mdt)
            assert(isa(Mdt, 'MyMetadata'), ...
                'Mdt must be of MyMetadata class.');
            
            param_names = fieldnames(Mdt.ParamList);
            for i=1:length(param_names)
                tag = param_names{i};
                
                if isprop(this, tag)
                    this.(tag) = Mdt.ParamList.(tag);
                end
            end
        end
    end
    
    methods (Access = protected)
        function createMetadata(this)
            this.Metadata = MyMetadata('title', class(this));
            
            % Add identification string 
            addParam(this.Metadata, 'idn', this.idn_str);

            for i = 1:length(this.command_names)
                cmd = this.command_names{i};
                addObjProp(this.Metadata, this, cmd, ...
                    'comment', this.CommandList.(cmd).info);
            end
        end
        
        % Create set methods for dynamic properties
        function f = createCommandSetFcn(~, tag)
            function commandSetFcn(this, val)
                
                % Validate new value
                vFcn = this.CommandList.(tag).validationFcn;
                if ~isempty(vFcn)
                    vFcn(val);
                end
                
                % Store the unprocessed value for quick reference in  
                % the future and value change tracking
                this.CommandList.(tag).last_value = val;
                    
                % Assign the value after post processing to the property
                pFcn = this.CommandList.(tag).postSetFcn;
                if ~isempty(pFcn)
                    val = pFcn(val);
                end

                this.(tag) = val;
                
                if this.CommandWriteEnabled.(tag)
                    
                    % Write the new value to the instrument
                    this.CommandList.(tag).writeFcn(this.(tag));
                    
                    if this.auto_sync
                        
                        % Confirm the changes by reading the state
                        sync(this);
                    end
                end
            end
            
            f = @commandSetFcn;
        end
        
        function f = createListValidationFcn(~, value_list)
            function listValidationFcn(val)
                assert( ...
                    any(cellfun(@(y) isequal(val, y), value_list)), ...
                    ['Value must be one from the following list:', ...
                    newline, var2str(value_list)]);
            end
            
            f = @listValidationFcn;
        end
        
        % Overload a method of matlab.mixin.CustomDisplay in order to
        % modify the display of object. This serves two purposes 
        % a) separate commands from other properties 
        % b) order commands in a systematic way
        function PrGroups = getPropertyGroups(this)
            cmds = this.command_names;
            
            % We separate the display of non-command properties from the
            % rest
            props = setdiff(properties(this), cmds);
            
            PrGroups = [matlab.mixin.util.PropertyGroup(props), ...
                matlab.mixin.util.PropertyGroup(cmds)];
        end
    end
    
    %% Set and Get methods
    methods
        function val = get.command_names(this)
            val = fieldnames(this.CommandList);
        end
        
        function set.idn_str(this, str)
            this.idn_str = toSingleLine(str);
        end
    end
end

