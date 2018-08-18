% Class for instruments supporting SCPI, features specialized framework for
% read/write commands
classdef MyScpiInstrument < MyInstrument
    
    properties (SetAccess=protected, GetAccess=public)
        %Contains a list of the commands available for the instrument as
        %well as the default values and input requirements
        CommandList=struct();
        %Parses commands using an inputParser object
        CommandParser;
    end
        
    properties (Dependent=true)
        command_names;
        command_no;
        write_commands;
        read_commands;
    end
    
    methods (Access=public)
        %% Class constructor
        function this=MyScpiInstrument(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            createCommandList(this);
            createCommandParser(this);
        end
        
        %% Low-level functions for reading and writing textual data to the device
        % These functions can be overloaded if the instrument does not
        % support visa communication or use non-standard command separators
        
        function writeCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';:');
                cmd_str=[cmd_str{1},';'];
                fprintf(this.Device, cmd_str);
            end
        end
        
        % Query commands and return resut as cell array of strings
        function res_list=queryCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';:');
                cmd_str=[':',cmd_str{1},';'];
                res_str=query(this.Device, cmd_str);
                % Drop the end-of-the-string symbol and split
                res_list=split(res_str(1:end-1),';');
            else
                res_list={};
            end
        end
        
        %% Read and write commands
        
        %Writes properties to device. Can take multiple inputs. With the
        %option all, the function writes default to all the
        %available writeable parameters.
        function writeProperty(this, varargin)
            %Parses the inputs using the CommandParser
            parse(this.CommandParser, varargin{:});

            if this.CommandParser.Results.all
                % If the 'all' is true, write all the commands
                exec=this.write_commands;
            else
                % Check which commands were passed values
                ind_val=cellfun(@(x)...
                    (~ismember(x, this.CommandParser.UsingDefaults)),...
                    this.write_commands);
                exec=this.write_commands(ind_val);
            end
            
            % create a list of textual strings to be sent to device
            exec_commands=cell(1,length(exec));
            for i=1:length(exec)
                %Create command using the right string spec
                cmd=[this.CommandList.(exec{i}).command,...
                    ' ',this.CommandList.(exec{i}).str_spec];
                val=this.CommandParser.Results.(exec{i});
                exec_commands{i}=sprintf(cmd, val);
            end
            %Sends commands to device
            writeCommand(this, exec_commands{:});
            for i=1:length(exec)
                %Assign written values to instrument properties
                this.(exec{i})=this.CommandParser.Results.(exec{i});
            end
        end
        
        % Wrapper for writeProperty that opens and closes the device
        function writePropertyHedged(this, varargin)
            openDevice(this);
            try
                writeProperty(this, varargin{:});
            catch
                warning('Error while writing the properties:');
                disp(varargin);
            end
            readProperty(this, 'all');
            closeDevice(this);
        end
        
        function result=readProperty(this, varargin)
            result = struct();
            read_all_flag = any(strcmp('all',varargin));          
            if read_all_flag
                % Read all the commands with read access 
                exec=this.read_commands;
            else
                ind_r=ismember(varargin,this.read_commands);
                exec=varargin(ind_r);
                if any(~ind_r)
                    % Issue warnings for commands not in the command_names
                    warning('The following are not valid read commands:');
                    disp(varargin(~ind_r));
                end
            end
            % Create a list of textual strings to be sent to device
            exec_commands=cellfun(...
                @(cmd)[this.CommandList.(cmd).command,'?'],exec,...
                'UniformOutput',false);
            % Query device
            res_list=queryCommand(this, exec_commands{:});
            % Assign outputs to the class properties
            if length(exec)==length(res_list)
                for i=1:length(exec)
                    result.(exec{i})=sscanf(res_list{i},...
                        this.CommandList.(exec{i}).str_spec);
                    %Assign the values to the MyInstrument properties
                    this.(exec{i})=result.(exec{i});
                end
            else
                warning(['Not all the properties could be read, ',...
                    'no instrument class values are not updated']);
            end
        end
        
        % Wrapper for readProperty that opens and closes the device
        function result=readPropertyHedged(this, varargin)
            openDevice(this);
            try
                result = readProperty(this, varargin{:});
            catch
                warning('Error while reading the properties:');
                disp(varargin);
            end
            closeDevice(this);
        end
        
        % Re-define readHeader function
        function HdrStruct=readHeader(this)
           Values=readPropertyHedged(this,'all');
           for i=1:length(this.read_commands)
               HdrStruct.(this.read_commands{i}).value=...
                   Values.(this.read_commands{i});
               HdrStruct.(this.read_commands{i}).str_spec=...
                   this.CommandList.(this.read_commands{i}).str_spec;
           end
        end
        
        %% Processing of the class variable values
        % Extend the property value based on val_list 
        function std_val = standardizeValue(this, cmd, varargin)
            if ~ismember(cmd,this.command_names)
                warning('%s is not a valid command',cmd);
                std_val = '';
                return
            end
            vlist = this.CommandList.(cmd).val_list;
            % The value to normalize can be explicitly passed as
            % varargin{1}, otherwise use this.cmd as value
            if isempty(varargin)
                val = this.(cmd);
            else
                val = varargin{1};
            end
            % find matching commands
            ismatch = false(1,length(vlist));
            for i=1:length(vlist)
                n = min([length(val), length(vlist{i})]);
                % compare first n symbols disregarding case
                ismatch(i) = strncmpi(val, vlist{i},n);
            end
            % out of matching names pick the longest
            if any(ismatch)
                mvlist = vlist(ismatch);
                %Finds the length of each element of mvlist
                n_el=cellfun(@(x) length(x), mvlist);
                %Sets std_val to the longest element
                std_val=mvlist{n_el==max(n_el)};

                % sets the property if value was not given explicitly 
                if isempty(varargin)
                    this.(cmd) = std_val;
                end
            else
                warning(['The value %s is not in the val_list ',...
                    'of %s command'], val, cmd)
                std_val = val;
            end
        end
        
        % Return the list of long command values excluding abbreviations
        function std_val_list = stdValueList(this, cmd)
            if ~ismember(cmd,this.command_names)
                warning('%s is not a valid command',cmd);
                std_val_list = {};
                return
            end
            vlist = this.CommandList.(cmd).val_list;
            % Select the commands, which appear only once in the beginnings 
            % of the strings in val_list
            long_val_ind = cellfun(...
                @(x)(sum(startsWith(vlist,x,'IgnoreCase',true))==1),vlist);
            std_val_list = vlist(long_val_ind); 
        end
        
        %% Auxiliary functions for auto format assignment to commands
        function str_spec=formatSpecFromAttributes(~,classes,attributes)
            if ismember('char',classes)
                str_spec='%s';
            elseif ismember('logical',classes)||...
                    (ismember('numeric',classes)&&...
                    ismember('integer',attributes))
                str_spec='%i';
            else
                %assign default value, i.e. double
                str_spec='%e';
            end
        end
        
        function [class,attribute]=attributesFromFormatSpec(~, str_spec)
            % find index of the first letter after the % sign
            ind_p=strfind(str_spec,'%');
            ind=ind_p+find(isletter(str_spec(ind_p:end)),1)-1;
            str_spec_letter=str_spec(ind);
            switch str_spec_letter
                case {'d','f','e','g'}
                    class={'numeric'};
                    attribute={};
                case 'i'
                    class={'numeric'};
                    attribute={'integer'};
                case 's'
                    class={'char'};
                    attribute={};
                case 'b'
                    class={'logical'};
                    attribute={};
                otherwise
                    % Any of the above classes will pass
                    class={'numeric','char','logical'};
                    attribute={};
            end
        end
    end
    
    methods (Access=protected)
        %% Command list handling
        %Adds a command to the CommandList
        function addCommand(this, tag, command, varargin)
            p=inputParser();
            addRequired(p,'tag',@ischar);
            addRequired(p,'command',@ischar);
            addParameter(p,'default','placeholder');
            addParameter(p,'classes',{},@iscell);
            addParameter(p,'attributes',{},@iscell);
            addParameter(p,'str_spec','%e',@ischar);
            % list of the values the variable can take, {} means no
            % restriction
            addParameter(p,'val_list',{},@iscell);
            addParameter(p,'access','rw',@ischar);
            parse(p,tag,command,varargin{:});

            %Adds the command to be sent to the device
            this.CommandList.(tag).command=command;
            this.CommandList.(tag).access=p.Results.access;
            this.CommandList.(tag).write_flag=contains(p.Results.access,'w');
            this.CommandList.(tag).read_flag=contains(p.Results.access,'r');
            this.CommandList.(tag).default=p.Results.default;
            this.CommandList.(tag).val_list=p.Results.val_list;
            
            % Adds the string specifier to the list. if the format
            % specifier is not given explicitly, try to infer
            if ismember('str_spec', p.UsingDefaults)
                this.CommandList.(tag).str_spec=...
                    formatSpecFromAttributes(this,p.Results.classes...
                    ,p.Results.attributes);
            elseif strcmp(p.Results.str_spec,'%b')
                % b is a non-system specifier to represent the
                % logical type
                this.CommandList.(tag).str_spec='%i';
            else
                this.CommandList.(tag).str_spec=p.Results.str_spec;
            end
            % Adds the attributes for the input to the command. If not
            % given explicitly, infer from the format specifier
            if ismember('classes',p.UsingDefaults)
                [this.CommandList.(tag).classes,...
                this.CommandList.(tag).attributes]=...
                attributesFromFormatSpec(this, p.Results.str_spec);
            else
                this.CommandList.(tag).classes=p.Results.classes;
                this.CommandList.(tag).attributes=p.Results.attributes;
            end
            
            % Adds a property to the class corresponding to the tag
            if ~isprop(this,tag)
                addprop(this,tag);
            end
            this.(tag)=p.Results.default;
        end
        
        %Creates inputParser using the command list
        function p = createCommandParser(this)
            %Use input parser
            %Requires input of the appropriate class
            p=inputParser;
            p.StructExpand=0;
            %Flag for whether the command should initialize the device with
            %defaults
            addParameter(p, 'all',false,@islogical);
            
            for i=1:length(this.write_commands)
                %Adds optional inputs for each command, with the
                %appropriate default value from the command list and the
                %required attributes for the command input.
                tag=this.write_commands{i};
                % Create validation function based on properties: 
                % class, attributes and list of values
                if ~isempty(this.CommandList.(tag).val_list)
                    if all(cellfun(@ischar, this.CommandList.(tag).val_list))
                        % for textual values use case insentice string comparison
                        v_func = @(x) any(cellfun(@(y) strcmpi(y, x),...
                            this.CommandList.(tag).val_list));
                    else
                        % for everything else compare as it is
                        v_func = @(x) any(cellfun(@(y) isequal(y, x),...
                            this.CommandList.(tag).val_list));
                    end
                else
                    v_func = @(x) validateattributes(x,...
                    this.CommandList.(tag).classes,...
                    this.CommandList.(tag).attributes);
                end
                addParameter(p, tag,...
                    this.CommandList.(tag).default, v_func);
            end
            this.CommandParser=p;
        end
        
        %Dummy empty function that needs to be redefined in a subclass and
        %contain addCommand statements
        function createCommandList(~)
        end
    end
    
    %% Get functions
    methods
        function command_names=get.command_names(this)
            command_names=fieldnames(this.CommandList);
        end
        
        function write_commands=get.write_commands(this)
            ind_w=structfun(@(x) x.write_flag, this.CommandList);
            write_commands=this.command_names(ind_w);
        end
        
        function read_commands=get.read_commands(this)
            ind_r=structfun(@(x) x.read_flag, this.CommandList);
            read_commands=this.command_names(ind_r);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
    end
end