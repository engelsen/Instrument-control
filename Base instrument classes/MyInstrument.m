% Generic instrument superclass

classdef MyInstrument < dynamicprops
    
    properties (Access = public)
        % Synchronize all properties after setting a new value to one
        auto_sync = true
    end
    
    properties (SetAccess = protected, GetAccess = public)
        CommandList = struct()
        
        % identification string
        idn_str=''
    end
    
    properties (Dependent = true)
        command_names
        command_no
    end
    
    events 
        NewSetting
    end
    
    methods (Access = public)
        function this = MyInstrument(varargin)
            createCommandList(this);
        end
        
        % Read all parameters of the physical device
        function sync(this)
            read_ind = structfun(@(x) ~isempty(x.readFcn), ...
                this.CommandList);
            read_cmds = this.command_names(read_ind);
            
            for i=1:length(read_cmds)
                tag = read_cmds{i};
                setCommand(this, tag, val, true);
            end
            
            % Signal value change
            triggerNewSetting(this, read_cmds);
        end
        
        function addCommand(this, tag, varargin)
            p=inputParser();
            
            % Name of the command
            addRequired(p,'tag', @(x)isvarname(x));
            
            % Functions for reading and writing the property value to the 
            % instrument
            addParameter(p,'readFcn',[], @(x)isa(x, 'function_handle'));
            addParameter(p,'writeFcn',[], @(x)isa(x, 'function_handle'));
            
            % Function applied before writeFcn
            addParameter(p,'validationFcn',[], ...
                @(x)isa(x, 'function_handle'));
            
            % Function or list of functions executed after updating the
            % class property value
            addParameter(p,'postSetFcn',[], ...
                @(x)(isa(x, 'function_handle') || (iscell(x) && ...
                all(cellfun(@(y)isa(y, 'function_handle'), x)))));
            
            addParameter(p,'value_list',{}, @iscell);
            addParameter(p,'default',[]);
            addParameter(p,'info','', @ischar);
            parse(p,tag,varargin{:});
            
            assert(~isprop(this, tag), ['Property named ' tag ...
                ' already exists in the class.']);
            
            this.CommandList.(tag) = p.Results;
            
            if ~ismember('value_list', p.UsingDefaults)
                assert(isempty(this.CommandList.(tag).validationFcn), ...
                    ['validationFcn is already assigned, cannot ' ...
                    'create a new one based on value_list']);
                this.CommandList.(tag).validationFcn = ...
                    @(x) any(cellfun(@(y) isequal(y, x),...
                    this.CommandList.(tag).value_list));
            end
            
            % Create and configure a dynamic property
            H = addprop(this, tag);
            
            H.GetAccess = 'public';
            
            if ~isempty(this.CommandList.(tag).writeFcn)
                H.SetAccess = 'public';
                H.SetMethod = @(x,y)this.setCommand(x,y,false);
            else
                H.SetAccess = 'protected';
            end
            
            this.(tag) = p.Results.default;
        end
        
        % Identification
        function [str, msg]=idn(this)
            assert(ismethod(this, 'queryString'), ['The instrument ' ...
                'class must define queryString method in order to ' ...
                'attempt identification.'])
            
            try
                [str,~,msg]=queryString(this,'*IDN?');
            catch ErrorMessage
                str='';
                msg=ErrorMessage.message;
            end   
            this.idn_str=str;
        end
        
        function triggerNewSetting(this, varargin)
            p=inputParser;
            addParameter(p, 'setting_name', @iscellstr);
            parse(p, varargin{:});
            
            EventData=MyNewSettingEvent();
            
            notify(this, 'NewSetting', EventData);
        end
    end
    
    methods (Access = protected)
        
        % Set method shared by all commands
        function setCommand(this, tag, val, prop_only)
            if ~prop_only
                vFcn = this.CommandList.(tag).validationFcn;
                if ~isempty(vFcn)
                    assert(vFcn(val), ['Value assigned to property ''' ...
                        tag ''' must satisfy ' func2str(vFcn) '.']);
                end
                
                % Write and confirm the new value by reading
                this.CommandList.(tag).writeFcn(val);
                
                if isempty(this.CommandList.(tag).readFcn) || ...
                        ~this.auto_sync
                    
                    % Assign the nominal value if it cannot or should not 
                    % be read
                    this.(tag) = val;
                    
                    % Signal value change
                    triggerNewSetting(this, {tag});
                end
                
                if this.auto_sync
                    sync(this);
                end
            else
                this.(tag) = val;
            end
        end
    end
    
    methods (Abstract = true, Access = protected)
        queryString(this, cmd)
        writeString(this, cmd)
        
        createCommandList(this)
    end
    
    %% Set and Get methods
    methods
        function val=get.command_names(this)
            val=fieldnames(this.CommandList);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
        
        function set.idn_str(this, str)
            this.idn_str=toSingleLine(str);
        end
    end
end

