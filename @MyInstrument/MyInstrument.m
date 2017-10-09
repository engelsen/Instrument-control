classdef MyInstrument < handle
    
    properties (SetAccess=immutable)
        name='';
        interface='';
        address='';
    end
    
    properties (SetAccess=protected, GetAccess=public)
        Gui
        Device
        CommandList
        CommandParser
    end
    
    properties (Dependent=true)
        command_names
        command_no
    end
    
    methods
        function this=MyInstrument(name, interface, address, gui_str)
            this.name=name;
            this.interface=interface;
            this.address=address;
            %Loads the gui from the input gui string
            this.Gui=guihandles(eval(gui_str));
            %Sets figure close function such that class will know when
            %figure is closed
            set(this.Gui.figure1, 'CloseRequestFcn',...
                @(hObject,eventdata) closeFigure(this, hObject, eventdata));
        end
        
        
        function delete(this)
            %Removes close function from figure, prevents infinite loop
            set(this.Gui.figure1,'CloseRequestFcn','');
            %Deletes the figure
            delete(this.Gui.figure1);
            %Removes the figure handle to prevent memory leaks
            this.Gui=[];
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            delete(this.Device);
            clear('this.Device');
        end
        
    end
    
    methods
        
        %Checks if the connection to the device is open
        function bool=isopen(this)
            bool=strcmp(this.Device.Status, 'open');
        end
        
        %Sends a read command to the device
        function result=read(this,command)
            result=query(this.Device, command);
        end
        
        %Writes to the device
        function write(this, command)
            fprintf(this.Device, command);
        end
        
        function writeProperty(this, varargin)
            %Parses the inputs using the CommandParser
            parse(this.CommandParser, varargin{:});
            
            %Finds the commands that are supplied by the user
            ind=~ismember(this.CommandParser.Parameters,...
                this.CommandParser.UsingDefaults);
            %Creates a list of commands to be executed
            exec=this.CommandParser.Parameters(ind);
            
            for i=1:length(exec)
                command=sprintf(this.CommandList.(exec{i}).command,...
                    this.CommandParser.Results.(exec{i}));
                write(this, command);
            end
        end
        
        %Adds a command to the CommandList
        function addCommand(this, name, command, default, attributes)
            %Checks that the command is named correctly - i.e. it has the
            %same name as a property of the class, specifically the one it
            %is modifying
            if ~isprop(this, name)
                error('All commands must have a name matching the property they modify')
            end
            
            %Adds the command to be sent to the device
            this.CommandList.(name).command=command;
            %Adds the default value 
            this.CommandList.(name).default=default;
            %Adds the necessary attributes for the input to the command
            this.CommandList.(name).attributes={attributes};
        end
        
        
        %Creates inputParser using the command list
        function createCommandParser(this)
            %Use input parser
            %Requires input of the appropriate class
            p=inputParser;
            p.StructExpand=0;
            

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
                    error('Could not open device')
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
        
        function command_names=get.command_names(this)
            command_names=fieldnames(this.CommandList);
        end
        
        function command_no=get.command_no(this)
            command_no=length(this.command_names);
        end
    end
    
    
    
end