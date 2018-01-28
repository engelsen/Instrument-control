classdef MyInstrument < dynamicprops
    
    properties (SetAccess=protected, GetAccess=public)
        name='';
        interface='';
        address='';
        visa_brand='';
        %Contains the device object. struct() is a dummy, as Device 
        %needs to always support properties for consistency.
        Device=struct();
        %Input parser for class constructor
        ConstructionParser;
        %Contains a list of the commands available for the instrument as
        %well as the default values and input requirements
        CommandList=struct();
        %Parses commands using an inputParser object
        CommandParser;
        %Trace object for storing data
        Trace=MyTrace();
    end
    
    properties (Constant=true)
        % Default parameters for VISA connection
        DEFAULT_INP_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_OUT_BUFF_SIZE = 1e7; % buffer size bytes
        DEFAULT_TIMEOUT = 10; % Timeout in s
        DEFAULT_VISA_BRAND = 'ni';
    end
        
    properties (Dependent=true)
        command_names;
        command_no;
        write_commands;
        read_commands;
    end
    
    events
        NewData;
    end
    
    methods (Access=private)
        function p = createConstructionParser(this)
            p=inputParser();
            % Ignore unmatched parameters
            p.KeepUnmatched = true;
            addRequired(p,'interface',@ischar);
            addRequired(p,'address',@ischar);
            addParameter(p,'name','',@ischar);
            addParameter(p,'visa_brand',this.DEFAULT_VISA_BRAND,@ischar);
            this.ConstructionParser=p;
        end
    end
    
    methods (Access=public)
        function this=MyInstrument(interface, address, varargin)
            p = createConstructionParser(this);
            parse(p,interface,address,varargin{:});      
            %Loads parsed variables into class properties
            this.name=p.Results.name;
            this.interface=p.Results.interface;
            this.address=p.Results.address;
            this.visa_brand=p.Results.visa_brand;
        end
        
        function delete(this)         
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            delete(this.Device);
            clear('this.Device');
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

            for i=1:length(exec)
                %Creates the write command using the right string spec
                write_command=[this.CommandList.(exec{i}).command,...
                    ' ',this.CommandList.(exec{i}).str_spec];
                %Gets the value to write to the device
                this.(exec{i})=this.CommandParser.Results.(exec{i});
                command=sprintf(write_command, this.(exec{i}));
                %Sends command to device
                fprintf(this.Device, command);
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
            % concatenate all commands in one string
            read_command=join(cellfun(...
                @(cmd)this.CommandList.(cmd).command,exec,...
                'UniformOutput',false),'?;:');
            read_command=[read_command{1},'?;'];
            res_str = query(this.Device,read_command);
            % drop the end-of-the-string symbol and split
            res_str = split(res_str(1:end-1),';');
            if length(exec)==length(res_str)
                for i=1:length(exec)
                    result.(exec{i})=sscanf(res_str{i},...
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
        
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
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
            % varargin{1}, otherwise use the property value
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
                str = mvlist{1};
                for i=1:length(mvlist)
                    if length(mvlist{i})>length(str)
                        str = mvlist{i};
                    end
                end
                std_val = str;
                % set the property if value was not given explicitly 
                if isempty(varargin)
                    this.(cmd) = std_val;
                end
            else
                std_val = val;
            end
        end
        
        % Create a string of property values
        function par_str = getConfigString(this)
            % Try to find out the device name
            if ~isempty(this.name)
                name_str = this.name;
            else
                try
                    openDevice(this);
                    name_str = query(this.Device,'*IDN?');
                    closeDevice(this);
                    % Remove the new line end symbol
                    name_str=name_str(1:end-1);
                catch
                    warning('Could not get the device name');
                    name_str = '';
                end
            end
            par_str = sprintf('Instrument name: %s\n',name_str);
            % Append the values of all the commands 
            rcmds=this.read_commands;
            for i=1:length(rcmds)
                new_str = sprintf(['\t',rcmds{i},'\t',...
                    this.CommandList.(rcmds{i}).str_spec,'\n'],...
                    this.(rcmds{i}));
                par_str = [par_str, new_str];
            end
        end
        
        %% Connect, open, configure and close the device
        % Connects to the device
        function connectDevice(this, interface, address)
            try
                % visa brand, DEFAULT_VISA_BRAND if not specified
                vb = this.visa_brand;
                switch lower(interface)
                    case 'instr_list'
                        % load the InstrumentList structure
                        InstrumentList = getLocalInstrList();
                        % In this case 'address' is the instrument name in
                        % the list
                        instr_name = address;
                        if ~isfield(InstrumentList, instr_name)
                            error('%s is not a field of InstrumentList',...
                                instr_name)
                        end
                        % A check to prevent hypothetical endless recursion
                        if isequal(InstrumentList.(instr_name).interface,'instr_list')
                            error('')
                        end
                        % Connect using the loaded parameters 
                        connectDevice(this,...
                            InstrumentList.(instr_name).interface,...
                            InstrumentList.(instr_name).address);
                        % Assign name automatically, but not overwrite if
                        % already specified
                        if isempty(this.name)
                            this.name = instr_name;
                        end
                    case 'constructor'
                        % in this case the 'address' is a command 
                        % (ObjectConstructorName) as returned by the 
                        % instrhwinfo
                        this.Device=eval(address);
                    case 'visa'
                        this.Device=visa(vb, address);
                    case 'tcpip'
                        this.Device= visa(vb, sprintf(...
                            'TCPIP0::%s::inst0::INSTR',this.address));
                    case 'usb'
                        this.Device=visa(vb, sprintf(...
                            'USB0::%s::INSTR',address));
                    otherwise
                        warning('Device is not connected: unknown interface');
                end
                configureDeviceDefault(this);
            catch
                warning('Device is not connected');
            end
        end
        
        % Opens the device if it is not open
        function openDevice(this)
            if ~isopen(this)
                try
                    fopen(this.Device);
                catch
                    % try to find and close all the devices with the same
                    % VISA resource name
                    try
                        instr_list=instrfind('RsrcName',this.Device.RsrcName);
                        fclose(instr_list);
                        fopen(this.Device);
                        warning('Multiple instrument objects of address %s exist',...
                            this.address);
                    catch
                        error('Could not open device')
                    end
                end
            end
        end
        
        % Closes the connection to the device
        function closeDevice(this)
            if isopen(this)
                fclose(this.Device);
            end
        end
        
        function configureDeviceDefault(this)
            dev_prop_list = properties(this.Device);
            if ismember('OutputBufferSize',dev_prop_list)
                this.Device.OutputBufferSize = this.DEFAULT_OUT_BUFF_SIZE;
            end
            if ismember('InputBufferSize',dev_prop_list)
                this.Device.InputBufferSize = this.DEFAULT_INP_BUFF_SIZE;
            end
            if ismember('Timeout',dev_prop_list)
                this.Device.Timeout = this.DEFAULT_TIMEOUT;
            end
        end
        
        %Checks if the connection to the device is open
        function bool=isopen(this)
            try
                bool=strcmp(this.Device.Status, 'open');
            catch
                warning('Cannot verify device Status property');
                bool=false;
            end
        end
        
        %% addCommand
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
                    v_func = @(x) any(cellfun(@(y) isequal(y, x),...
                    this.CommandList.(tag).val_list));
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