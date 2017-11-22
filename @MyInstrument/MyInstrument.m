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
        
    properties (Dependent=true)
        command_names;
        command_no;
    end
    
    events
        NewData;
    end
    
    methods (Access=public)
        function this=MyInstrument(name, interface, address, varargin)
            createParser(this);
            parse(this.Parser,name,interface,address,varargin{:});
            
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
                set(this.Gui.figure1, 'CloseRequestFcn',...
                    @(hObject,eventdata) closeFigure(this, hObject, ...
                    eventdata));
            end
        end
        
        function delete(this)
            %Removes close function from figure, prevents infinite loop
            if this.enable_gui
                set(this.Gui.figure1,'CloseRequestFcn','');
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
        %option init_device, the function writes default to all the
        %available writeable parameters.
        function writeProperty(this, varargin)
            %Parses the inputs using the CommandParser
            parse(this.CommandParser, varargin{:});

            if ~this.CommandParser.Results.write_all_defaults
                %Finds the writeable commands that are supplied by the user
                ind=~ismember(this.CommandParser.Parameters,...
                    this.CommandParser.UsingDefaults);
                %Creates a list of commands to be executed
                exec=this.CommandParser.Parameters(ind);
            else
                exec=this.CommandParser.Parameters;
                %Removes write_all_defaults from the list of commands to be
                %executed
                exec(strcmp(exec,'write_all_defaults'))=[];
            end
            
            for i=1:length(exec)
                %Creates the write command using the right string spec
                write_command=[this.CommandList.(exec{i}).command,...
                    ' %',this.CommandList.(exec{i}).str_spec];
                %Gets the value to write to the device
                this.(exec{i})=this.CommandParser.Results.(exec{i});
                command=sprintf(write_command, this.(exec{i}));
                %Sends command to device
                fprintf(this.Device, command);
            end
        end
        
        %Wrapper for writeProperty that opens the device
        function writePropertyHedged(this, varargin)
            this.openDevice();
            try
                this.writeProperty(varargin{:});
            catch
                disp('Error while writing the properties:');
                disp(varargin);
            end
            this.readAll();
            closeDevice(this);
        end
        
        function result=readProperty(this, varargin)
            result=struct();
            ind=cellfun(@(x) contains(this.CommandList.(x).access,'r'),...
                varargin);
            
            exec=varargin(ind);
            
            if any(~ind)
                disp('Some specified properties are write-only:')
                non_exec=varargin(~ind);
                disp(non_exec{:});
            end
            
            
            for i=1:length(exec)
                %Creates the correct read command
                read_command=[this.CommandList.(exec{i}).command,'?'];
                
                %Reads the property from the device and stores it in the
                %correct place
                res_str = query(this.Device,read_command);
                if strcmp(this.CommandList.(exec{i}).attributes{1},'string')
                    result.(exec{i})= res_str(1:(end-1));
                else
                    result.(exec{i})= str2double(res_str);
                end
            end
        end

        function result = readPropertyHedged(this, varargin)
            this.openDevice();
            try
                result = this.readProperty(varargin{:});
            catch
                disp('Error while reading the properties:');
                disp(varargin);
            end
            this.closeDevice();
        end
        
        % Execute all the read commands and update corresponding properties
        function readAll(this)
            ind=cellfun(@(x) contains(this.CommandList.(x).access,'r'),...
                this.command_names);
            result=readProperty(this, this.command_names{ind});
            res_names=fieldnames(result);
            for i=1:length(res_names)
                this.(res_names{i})=result.(res_names{i});
            end
        end
        
    end
    
    methods (Access=private)
        function createParser(this)
            p=inputParser;
            addRequired(p,'name',@ischar);
            addRequired(p,'interface',@ischar);
            addRequired(p,'address',@ischar);
            addParameter(p,'gui','placeholder',@ischar);
            this.Parser=p;
        end
    end
    
    methods (Access=protected)
        %Triggers event for acquired data
        function triggerNewData(this)
            notify(this,'NewData')
        end
        
        %Checks if the connection to the device is open
        function bool=isopen(this)
            bool=strcmp(this.Device.Status, 'open');
        end
             
        %Adds a command to the CommandList
        function addCommand(this, tag, command, varargin)
            p=inputParser;
            addRequired(p,'tag',@ischar);
            addRequired(p,'command',@ischar);
            addParameter(p,'default','placeholder');
            addParameter(p,'attributes','placeholder',@iscell);
            addParameter(p,'str_spec','d',@ischar);
            %If the write flag is on, it means this command can be used to
            %write a parameter to the device
            addParameter(p,'access','rw',@ischar);
            parse(p,tag,command,varargin{:});

            %Adds the command to be sent to the device
            this.CommandList.(tag).command=command;
            this.CommandList.(tag).access=p.Results.access;
            
            write_flag=contains(p.Results.access,'w');
%             read_flag=contains(p.Results.access,'r');
            
            %Adds a default value and the attributes the inputs must have
            %and creates a new property in the class
            if write_flag
                %Adds the string specifier to the list
                this.CommandList.(tag).str_spec=p.Results.str_spec;
                %Adds the default value
                this.CommandList.(tag).default=p.Results.default;
                %Adds the necessary attributes for the input to the command
                this.CommandList.(tag).attributes=p.Results.attributes;
                %Adds a conversion factor for displaying the value
                this.CommandList.(tag).conv_factor=p.Results.conv_factor;
                %Adds a property to the class corresponding to the tag
                addprop(this,tag);
            end
        end
        
        %Creates inputParser using the command list
        function createCommandParser(this)
            %Use input parser
            %Requires input of the appropriate class
            p=inputParser;
            p.StructExpand=0;
            %Flag for whether the command should initialize the device with
            %defaults
            addParameter(p, 'write_all_defaults',false,@islogical);
            
            for i=1:this.command_no
                %Adds optional inputs for each command, with the
                %appropriate default value from the command list and the
                %required attributes for the command input.
                addParameter(p, this.command_names{i},...
                    this.CommandList.(this.command_names{i}).default),...
                    @(x) validateattributes(x,...
                    this.CommandList.(this.command_names{i}).attributes{1:end});
            end
            this.CommandParser=p;
        end
        
        %Connects to the device if it is not connected
        function openDevice(this)
            if ~isopen(this)
                try
                    fopen(this.Device);
                catch
                    try
                        instr_list=instrfind('RemoteHost',this.address);
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
                try
                    fclose(this.Device);
                catch
                    
                    error('Could not close device')
                end
            end
        end
        
        %Close figure callback simply calls delete function for class
        function closeFigure(this,~,~)
            delete(this);
        end
    end
    
    %% Get functions
    methods
        function command_names=get.command_names(this)
            command_names=fieldnames(this.CommandList);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
    end
end