

classdef MyInstrument < dynamicprops
    
    properties (Access = public)
        % Synchronize all properties after every new value
        auto_sync = true
    end
    
    properties (SetAccess = protected, GetAccess = public)
        CommandList = struct()
    end
    
    properties (Dependent = true)
        command_names
        write_command_names
        read_command_names
        command_no
    end
    
    methods (Access = public)
        function obj = MyInstrument(varargin)
            
        end
        
        % Read all parameters of the physical device
        function sync(this)
            wc = this.read_command_names;
            
            for i=1:length(wc)
                tag = wc{i};
                val = this.CommandList.(tag).read_fcn();
                setCommand(this, tag, val, false);
            end
        end
    end
    
    methods (Access = protected)
        function addCommand(this, tag, varargin)
            p=inputParser();
            addRequired(p,'tag', @(x)isvarname(x));
            addParameter(p,'read_fcn',[], @(x)isa(x, 'function_handle'));
            addParameter(p,'write_fcn',[], @(x)isa(x, 'function_handle'));
            addParameter(p,'valudation_fcn',[], ...
                @(x)isa(x, 'function_handle'));
            addParameter(p,'value_list',{}, @iscell);
            addParameter(p,'info','', @ischar);
            parse(p,tag,varargin{:});
            
            this.CommandList.(tag) = p.Results;
            
            if ~ismember('value_list', p.UsingDefaults)
                assert(isempty(this.CommandList.(tag).validation_fcn), ...
                    ['validation_fcn is already assigned, cannot ' ...
                    'create a new one based on value_list']);
                this.CommandList.(tag).valudation_fcn = ...
                    @(x) any(cellfun(@(y) isequal(y, x),...
                            this.CommandList.(tag).value_list));
            end
            
            assert(~isprop(this,tag), ['Property named ' tag ...
                ' already exists in the class.']);
            
            H = addprop(this,tag);
            
            if ~isempty(this.CommandList.(tag).write_fcn)
                H.SetAccess = 'public';
                H.SetMethod = @(x,y)this.setCommand(x,y,true);
            else
                H.SetAccess = 'protected';
            end
        end
        
        function setCommand(this, tag, val, enable_write)
            if enable_write
                % Write and confirm the new value by reading
                assert(this.CommandList.(tag).valudation_fcn(val));
                this.CommandList.(tag).write_fcn(val);
                if this.auto_sync
                    sync(this);
                end
                if isempty(this.CommandList.(tag).read_fcn)
                    % Assign the nominal value if it cannot be read
                    this.(tag) = val;
                end
            else
                this.(tag) = val;
            end
        end
    end
    
    %% Set and Get functions
    methods
        function val=get.command_names(this)
            val=fieldnames(this.CommandList);
        end
        
        function val=get.write_command_names(this)
            ind_w=structfun(@(x) ~isempty(x.write_fcn), this.CommandList);
            val=this.write_command_names(ind_w);
        end
        
        function val=get.read_command_names(this)
            ind_r=structfun(@(x) ~isempty(x.write_fcn), this.CommandList);
            val=this.command_names(ind_r);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
    end
end

