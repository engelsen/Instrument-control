classdef MyTrace < handle
    properties
        x=[];
        y=[];
        name='placeholder';
        Color='b';
        Marker='.';
        LineStyle='-'
        MarkerSize=6;
        Parser;
        name_x='x';
        name_y='y';
        unit_x='';
        unit_y='';
        save_dir='';
        load_path='';
    end
    
    properties (Dependent=true)
        label_x;
        label_y;
    end
    
    methods
        function this=MyTrace(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this,true);
            
            if ~ismember('load_path',this.Parser.UsingDefaults)
                loadTrace(this,this.load_path);
            end
        end
        
        %Creates the input parser for the class. Includes default values
        %for all optional parameters.
        function createParser(this)
            p=inputParser;
            addOptional(p,'name','placeholder');
            addOptional(p,'x',[]);
            addOptional(p,'y',[]);
            addParameter(p,'Color','b');
            addParameter(p,'Marker','none');
            addParameter(p,'LineStyle','-');
            addParameter(p,'MarkerSize',6);
            addParameter(p,'unit_x','x');
            addParameter(p,'unit_y','y');
            addParameter(p,'name_x','x');
            addParameter(p,'name_y','y');
            %Default save folder is the current directory upon
            %instantiation
            addParameter(p,'save_dir',pwd);
            addParameter(p,'load_path','');
            this.Parser=p;
        end
        
        %Defines the save function for the class. Saves the data with
        %column headers as label_x and label_y
        function save(this,varargin)
            %Allows all options of the class as inputs for the save
            %function, to change the name or save directory.
            parse(this.Parser,varargin{:});
            parseInputs(this,false);
            %Creates save directory if it does not exist
            if ~exist(this.save_dir,'dir')
                mkdir(this.save_dir)
            end
            %Creates a file name out of the name of the class and the save
            %directory
            filename=[this.save_dir,'\',this.name,'.txt'];
            %Creates the file
            fileID=fopen(filename,'w');
            
            %Finds appropriate column width
            cw=max([length(this.label_y),length(this.label_x)]);
            
            %Makes a format string with the correct column width. %% makes
            %a % symbol in sprintf, thus if cw=14, below is %14s\t%14s\r\n.
            %\r\n prints a carriage return, ensuring linebreak in NotePad.
            fprintf(fileID,sprintf('%%%ds\t%%%ds\r\n',cw,cw),...
                this.label_x, this.label_y);
            %Saves in scientific notation with correct column width defined
            %above. Again if cw=14, we get %14.3e\t%14.3e\r\n
            fprintf(fileID,sprintf('%%%d.3e\t%%%d.3e\r\n',cw,cw),...
                [this.x; this.y]);
            fclose(fileID);
        end
        
        function loadTrace(this, file_path)
            if ~exist(this.load_path,'file')
                error('File does not exist, please choose a different load path')
            end
            load_data=tdfread(file_path);
            this.load_path=file_path;
            data_labels=fieldnames(load_data);
            %Code for left bracket
            ind_start=strfind(data_labels, '0x28');
            %Code for right bracket
            ind_stop=strfind(data_labels, '0x29');
            
            
            col_name={'x','y'};
            for i=1:2
                if ~isempty(ind_start) && ~isempty(ind_stop)
                    %Extracts the data labels from the file
                    this.(sprintf('unit_%s',col_name{i}))=...
                        data_labels{i}((ind_start{i}+4):(ind_stop{i}-1));
                    this.(sprintf('name_%s',col_name{i}))=...
                        data_labels{i}(1:(ind_start{i}-2));
                end
                %Loads the data into the trace
                this.(col_name{i})=load_data.(data_labels{i});
            end
        end

        %Sets the class variables to the inputs from the inputParser. Can
        %be used to reset class to default values if default_flag=true.
        function parseInputs(this, default_flag)
            for i=1:length(this.Parser.Parameters)
                %Sets the value if there was an input or if the default
                %flag is on. The default flag is used to reset the class to
                %its default values.
                if default_flag || ~any(ismember(this.Parser.Parameters{i},...
                        this.Parser.UsingDefaults))
                    this.(this.Parser.Parameters{i})=...
                        this.Parser.Results.(this.Parser.Parameters{i});
                end
            end
        end
        
        %Plots the trace on the given axes, using the class variables to
        %define colors, markers, lines and labels. Takes all optional
        %parameters of the class as inputs.
        function plotTrace(this,plot_axes,varargin)
            assert(exist('plot_axes','var') && ...
                isa(plot_axes,'matlab.graphics.axis.Axes'),...
                'Please input axes to plot in.') 
            assert(isequal(size(this.x), size(this.y)) || ...
                (isvector(this.x) && isvector(this.y) && ...
                numel(this.x) == numel(this.y)),...
                'The length of x and y must be identical to make a plot')
            parse(this.Parser,varargin{:})
            parseInputs(this,false);
            plot(plot_axes,this.x,this.y,'Color',this.Color,'LineStyle',...
                this.LineStyle,'Marker',this.Marker,...
                'MarkerSize',this.MarkerSize)
            xlabel(plot_axes,this.label_x,'Interpreter','LaTeX');
            ylabel(plot_axes,this.label_y,'Interpreter','LaTeX');
            set(plot_axes,'TickLabelInterpreter','LaTeX');
        end
        
        
        %Set function for Color. Checks if it is a valid color.
        function set.Color(this, Color)
            assert(iscolor(Color),...
                '%s is not a valid MATLAB default color or RGB triplet',...
                Color);
            this.Color=Color;
        end
        
        %Set function for Marker. Checks if it is a valid
        %marker style.
        function set.Marker(this, Marker)
            assert(ismarker(Marker),...
                '%s is not a valid MATLAB MarkerStyle',Marker);
            this.Marker=Marker;
        end
        
        %Set function for x, checks if it is a vector of doubles.
        function set.x(this, x)
            assert(isnumeric(x),...
                'Data must be of class double');
            this.x=x;
        end
        
        %Set function for y, checks if it is a vector of doubles.
        function set.y(this, y)
            assert(isnumeric(y),...
                'Data must be of class double');
            this.y=y;
        end
        
        %Set function for LineStyle, checks if input is a valid line style.
        function set.LineStyle(this, LineStyle)
            assert(isline(LineStyle),...
                '%s is not a valid MATLAB LineStyle',LineStyle);
            this.LineStyle=LineStyle;
        end
        
        %Set function for MarkerSize, checks if input is a positive number.
        function set.MarkerSize(this, MarkerSize)
            assert(isnumeric(MarkerSize) && MarkerSize>0,...
                'MarkerSize must be a numeric value greater than zero');
            this.MarkerSize=MarkerSize;
        end
        
        %Set function for name, checks if input is a string.
        function set.name(this, name)
            assert(ischar(name),'Name must be a string, not a %s',...
                class(name));
            this.name=name;
        end
        
        %Set function for unit_x, checks if input is a string.
        function set.unit_x(this, unit_x)
            assert(ischar(unit_x),'Unit must be a string, not a %s',...
                class(unit_x));
            this.unit_x=unit_x;
        end
        
        %Set function for unit_y, checks if input is a string
        function set.unit_y(this, unit_y)
            assert(ischar(unit_y),'Unit must be a string, not a %s',...
                class(unit_y));
            this.unit_y=unit_y;
        end
        
        %Set function for name_x, checks if input is a string
        function set.name_x(this, name_x)
            assert(ischar(name_x),'Name must be a string, not a %s',...
                class(name_x));
            this.name_x=name_x;
        end
        
        %Set function for name_y, checks if input is a string
        function set.name_y(this, name_y)
            assert(ischar(name_y),'Name must be a string, not a %s',...
                class(name_y));
            this.name_y=name_y;
        end
        
        function set.load_path(this, load_path)
            assert(ischar(load_path),'File path must be a string, not a %s',...
                class(load_path));
            this.load_path=load_path;
        end
        
        %Get function for label_x, creates label from name_x and unit_x.
        function label_x=get.label_x(this)
            label_x=sprintf('%s (%s)', this.name_x, this.unit_x);
        end
        
        %Get function for label_y, creates label from name_y and unit_y.
        function label_y=get.label_y(this)
            label_y=sprintf('%s (%s)', this.name_y, this.unit_y);
        end
        
    end
end