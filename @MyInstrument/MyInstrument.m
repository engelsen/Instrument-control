classdef MyInstrument < dynamicprops
    
    properties (SetAccess=protected, GetAccess=public)
        name='';
        interface='';
        address='';
        %Logical for whether gui is enabled
        enable_gui=false;
        %Contains the GUI handles
        Gui;
        %Contains the device object
        Device;
        %Input parser for class constructor
        Parser;
        %Contains a list of the commands available for the instrument as
        %well as the default values and input requirements
        CommandList;
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
    end
    
    events
        NewData;
    end
    
    methods (Access=private)
        function createParser(this)
            p=inputParser();
            addRequired(p,'interface',@ischar);
            addRequired(p,'address',@ischar);
            addParameter(p,'name','',@ischar);
            addParameter(p,'gui','',@ischar);
            addParameter(p,'visa_brand',this.DEFAULT_VISA_BRAND,@ischar);
            this.Parser=p;
        end
    end
    
    methods (Access=public)
        function this=MyInstrument(interface, address, varargin)
            createParser(this);
            parse(this.Parser,interface,address,varargin{:});
            
            %Loads parsed variables into class properties
            this.name=this.Parser.Results.name;
            this.interface=this.Parser.Results.interface;
            this.address=this.Parser.Results.address;
            this.enable_gui=~ismember('gui',this.Parser.UsingDefaults);
            
            %If a gui input is given, load the gui
            if this.enable_gui
                %Loads the gui from the input gui string
                this.Gui=guihandles(eval(this.Parser.Results.gui));
                %Sets figure close function such that class will know when
                %figure is closed
                ind=structfun(@(x) isa(x,'matlab.ui.Figure'),...
                    this.Gui);
                names=fieldnames(this.Gui);
                set(this.Gui.(names{ind}), 'CloseRequestFcn',...
                    @(hObject,eventdata) closeFigure(this, hObject, ...
                    eventdata));
            end
        end
        
        function delete(this)
            %Removes close function from figure, prevents infinite loop
            if this.enable_gui
                ind=structfun(@(x) isa(x,'matlab.ui.Figure'),...
                    this.Gui);
                names=fieldnames(this.Gui);
                set(this.Gui.(names{ind}), 'CloseRequestFcn',...
                    @(hObject,eventdata) closeFigure(this, hObject, ...
                    eventdata));
                %Deletes the figure handles
                structfun(@(x) delete(x), this.Gui);
                %Removes the figure handle to prevent memory leaks
                this.Gui=[];
            end
            
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            delete(this.Device);
            clear('this.Device');
        end
        
        %Clears data from trace to save memory.
        function clearData(this)
            this.Trace.x=[];
            this.Trace.y=[];
        end      
        
        %Writes properties to device. Can take multiple inputs. With the
        %option all, the function writes default to all the
        %available writeable parameters.
        function writeProperty(this, varargin)
            %Parses the inputs using the CommandParser
            parse(this.CommandParser, varargin{:});
            % Finds writable commands to be included in the execution list
            ind_w=structfun(@(x) x.write_flag, this.CommandList);
            if this.CommandParser.Results.all
                % If the 'all' is true, write all the commands
                ind=ind_w;
            else
                % Check which commands were passed values
                ind_val=cellfun(@(x)...
                    (~ismember(x, this.CommandParser.UsingDefaults)),...
                    this.command_names);
                ind=ind_w&ind_val;
                if any((~ind_w)&ind_val)
                    % Issue warnings for read-only commands
                    warning('The following commands are read only:');
                    disp(this.command_names((~ind_w)&ind_val));
                end
            end
            exec=this.command_names(ind);
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
            this.openDevice();
            try
                this.writeProperty(varargin{:});
            catch
                warning('Error while writing the properties:');
                disp(varargin);
            end
            this.readProperty('all');
            this.closeDevice();
        end
        
        function result=readProperty(this, varargin)
            result = struct();
            read_all_flag = any(strcmp('all',varargin));
            
            if read_all_flag
                % Read all the commands with read access 
                ind=structfun(@(x) x.read_flag, this.CommandList);
                exec=this.command_names(ind);
            else
                ind_val=ismember(varargin,this.command_names);
                varargin_val=varargin(ind_val);
                if any(~ind_val)
                    % Issue warnings for commands not in the command_names
                    warning('The following are not valid commands:');
                    disp(varargin{~ind_val});
                end
                ind_r=cellfun(@(x) this.CommandList.(x).read_flag,...
                    varargin_val);
                if any(~ind_r)
                    % Issue warnings for write-only commands
                    warning('The following commands are write only:');
                    disp(varargin_val{~ind_r});
                end
                exec=varargin_val(ind_r);
            end
            % Iterate over the commands list
            for i=1:length(exec)
                %Creates the correct read command
                read_command=[this.CommandList.(exec{i}).command,'?'];
                %Reads the property from the device and stores it in the
                %correct place
                res_str = query(this.Device,read_command);
                if ismember('char',this.CommandList.(exec{i}).classes)
                    result.(exec{i})= res_str(1:(end-1));
                else
                    result.(exec{i})= str2double(res_str);
                end
                %Assign the values to the MyInstrument properties
                this.(exec{i})=result.(exec{i});
            end
        end
        
        % Wrapper for readProperty that opens and closes the device
        function result = readPropertyHedged(this, varargin)
            this.openDevice();
            try
                result = this.readProperty(varargin{:});
            catch
                warning('Error while reading the properties:');
                disp(varargin);
            end
            this.closeDevice();
        end
        
        %Connects to the device if it is not connected
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
        
        %Closes the connection to the device
        function closeDevice(this)
            if isopen(this)
                fclose(this.Device);
            end
        end
        
        function configureDefaultVisa(this)
            this.Device.OutputBufferSize = this.DEFAULT_OUT_BUFF_SIZE;
            this.Device.InputBufferSize = this.DEFAULT_INP_BUFF_SIZE;
            this.Device.Timeout = this.DEFAULT_TIMEOUT;
        end
    end
    
    methods (Access=public)
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
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
             
        %Adds a command to the CommandList
        function addCommand(this, tag, command, varargin)
            p=inputParser();
            addRequired(p,'tag',@ischar);
            addRequired(p,'command',@ischar);
            addParameter(p,'default','placeholder');
            addParameter(p,'classes','placeholder',@iscell);
            addParameter(p,'attributes','placeholder',@iscell);
            addParameter(p,'str_spec','%d',@ischar);
            addParameter(p,'access','rw',@ischar);
            parse(p,tag,command,varargin{:});

            %Adds the command to be sent to the device
            this.CommandList.(tag).command=command;
            this.CommandList.(tag).access=p.Results.access;
            
            this.CommandList.(tag).write_flag=contains(p.Results.access,'w');
            this.CommandList.(tag).read_flag=contains(p.Results.access,'r');
            
            %Adds a default value and the attributes the inputs must have
            %and creates a new property in the class
            if this.CommandList.(tag).write_flag
                % Adds the string specifier to the list. if the format
                % specifier is not given explicitly, try to infer
                if ismember('str_spec',p.UsingDefaults)
                    this.CommandList.(tag).str_spec=...
                        formatSpecFromAttributes(this,p.Results.classes...
                        ,p.Results.attributes);
                else
                    if strcmp(p.Results.str_spec,'%b')
                        % b is a non-system specifier to represent the
                        % logical type
                        this.CommandList.(tag).str_spec='%i';
                    else
                        this.CommandList.(tag).str_spec=p.Results.str_spec;
                    end
                end
                % Adds the default value
                this.CommandList.(tag).default=p.Results.default;
                % Adds the attributes for the input to the command. If not
                % given explicitly, infer from the format specifier
                if ismember('classes',p.UsingDefaults)
                    [this.CommandList.(tag).classes,...
                    this.CommandList.(tag).attributes]=...
                    AttributesFromFormatSpec(this, p.Results.str_spec);
                else
                    this.CommandList.(tag).classes=p.Results.classes;
                    this.CommandList.(tag).attributes=p.Results.attributes;
                end
            end
            % Adds a property to the class corresponding to the tag
            if ~isprop(this,tag)
                addprop(this,tag);
            end
            this.(tag)=p.Results.default;
        end
        
        %Creates inputParser using the command list
        function createCommandParser(this)
            %Use input parser
            %Requires input of the appropriate class
            p=inputParser;
            p.StructExpand=0;
            %Flag for whether the command should initialize the device with
            %defaults
            addParameter(p, 'all',false,@islogical);
            
            for i=1:length(this.command_names)
                %Adds optional inputs for each command, with the
                %appropriate default value from the command list and the
                %required attributes for the command input.
                tag=this.command_names{i};
                addParameter(p, tag,...
                    this.CommandList.(tag).default,...
                    @(x) validateattributes(x,...
                    this.CommandList.(tag).classes,...
                    this.CommandList.(tag).attributes));
            end
            this.CommandParser=p;
        end
        
        function str_spec=formatSpecFromAttributes(~,classes,attributes)
            if ismember('char',classes)
                str_spec='%s';
            elseif ismember('logical',classes)||...
                    (ismember('numeric',classes)&&...
                    ismember('integer',attributes))
                str_spec='%i';
            else
                %assign default value, i.e. double
                str_spec='%d';
            end
        end
        
        function [class,attribute]=AttributesFromFormatSpec(~, str_spec)
            ind=strfind(str_spec,'%');
            str_spec_letter=str_spec(ind+1);
            switch str_spec_letter
                case 'd'
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
                    class={};
                    attribute={};
            end
        end
        
        %Close figure callback simply calls delete function for class
        function closeFigure(this,~,~)
            delete(this);
        end
    end
    
    % Get functions
    methods
        function command_names=get.command_names(this)
            command_names=fieldnames(this.CommandList);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
    end
end