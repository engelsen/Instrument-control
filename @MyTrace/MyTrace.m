% Class for XY data representation with labelling, plotting and
% saving/loading functionality
classdef MyTrace < handle & matlab.mixin.Copyable
    properties (Access=public)
        x=[];
        y=[];
        name_x='x';
        name_y='y';
        unit_x='';
        unit_y='';
        filename='placeholder';
        save_dir='';
        load_path='';
        save_pres=15;
        overwrite_flag
        %Cell that contains handles the trace is plotted in
        hlines={};
    end
    
    properties (Access=private)
        Parser;
    end
    
    properties (Dependent=true)
        label_x;
        label_y;
    end
    methods (Access=private)
                %Creates the input parser for the class. Includes default values
        %for all optional parameters.
        function createParser(this)
            p=inputParser;
            addParameter(p,'filename','placeholder');
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'unit_x','x');
            addParameter(p,'unit_y','y');
            addParameter(p,'name_x','x');
            addParameter(p,'name_y','y');
            %Default save folder is the current directory upon
            %instantiation
            addParameter(p,'save_dir',pwd);
            addParameter(p,'load_path','');
            addParameter(p,'save_pres',15);
            addParameter(p,'overwrite_flag',false);
            this.Parser=p;
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
    end
    
    methods (Access=public)
        function this=MyTrace(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this,true);
            
            if ~ismember('load_path',this.Parser.UsingDefaults)
                loadTrace(this,this.load_path);
            end
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
            fullfilename=fullfile(this.save_dir,[this.filename,'.txt']);
            if exist(fullfilename,'file') && ~this.overwrite_flag
                switch questdlg('Would you like to overwrite?',...
                        'File already exists', 'Yes', 'No', 'No')
                    case 'Yes'
                        this.overwrite_flag=1;
                    otherwise
                        warning('No file written as %s already exists',...
                            fullfilename);
                        return
                end
            end
            
            %Creates the file
            fileID=fopen(fullfilename,'w');
            
            %MATLAB returns -1 for the fileID if the file could not be
            %opened
            if fileID==-1
                errordlg(sprintf('File %s could not be created.',...
                    fullfilename),'File error');
                return
            end
            
            %Finds appropriate column width
            cw=max([length(this.label_y),length(this.label_x),...
                this.save_pres+7]);

            %Pads the vectors if they are not equal length
            diff=length(this.x)-length(this.y);
            if diff<0
                this.x=[this.x;zeros(-diff,1)];
                warning(['Zero padded x vector as the saved vectors are',...
                    ' not of the same length']);
            elseif diff>0
                this.y=[this.y;zeros(diff,1)];
                warning(['Zero padded y vector as the saved vectors are',...
                    ' not of the same length']);
            end

            %Makes a format string with the correct column width. %% makes
            %a % symbol in sprintf, thus if cw=18, below is %18s\t%18s\r\n.
            %\r\n prints a carriage return, ensuring linebreak in NotePad.
            title_format_str=sprintf('%%%is\t%%%is\r\n',cw,cw);
            fprintf(fileID,title_format_str,...
                this.label_x, this.label_y);
            %Saves in scientific notation with correct column width defined
            %above. Again if cw=20, we get %14.10e\t%14.10e\r\n
            data_format_str=sprintf('%%%i.%ie\t%%%i.%ie\r\n',...
                cw,this.save_pres,cw,this.save_pres);
            fprintf(fileID,data_format_str,[this.x, this.y]');
            fclose(fileID);
        end
        
        function clearData(this)
            this.x=[];
            this.y=[];
        end
        
        function loadTrace(this, file_path)
            if ~exist(file_path,'file')
                error('File does not exist, please choose a different load path')
            end

            read_opts=detectImportOptions(file_path);
            DataTable=readtable(file_path,read_opts);
            
            data_labels=DataTable.Properties.VariableNames;
            
            %Finds where the unit is specified, within parantheses.
            %Forces indices to be in cells for later.
            ind_start=strfind(data_labels, '(','ForceCellOutput',true);
            ind_stop=strfind(data_labels, ')','ForceCellOutput',true);
            
            col_name={'x','y'};
            for i=1:length(ind_start)
                if ~isempty(ind_start{i}) && ~isempty(ind_stop{i})
                    %Extracts the data labels from the file
                    this.(sprintf('unit_%s',col_name{i}))=...
                        data_labels{i}((ind_start{i}+4):(ind_stop{i}-1));
                    this.(sprintf('name_%s',col_name{i}))=...
                        data_labels{i}(1:(ind_start{i}-2));
                end
                %Loads the data into the trace
                this.(col_name{i})=DataTable.(data_labels{i});
            end
            this.load_path=file_path;
        end
        
        %Allows setting of multiple properties in one command.
        function setTrace(this, varargin)
            parse(this.Parser,varargin{:})
            parseInputs(this, false);
        end

        %Plots the trace on the given axes, using the class variables to
        %define colors, markers, lines and labels. Takes all optional
        %parameters of the class as inputs.
        function plotTrace(this,plot_axes,varargin)
            %Checks that there are axes to plot
            assert(exist('plot_axes','var') && ...
                (isa(plot_axes,'matlab.graphics.axis.Axes')||...
                isa(plot_axes,'matlab.ui.control.UIAxes')),...
                'Please input axes to plot in.')
            %Checks that x and y are the same size
            assert(validatePlot(this),...
                'The length of x and y must be identical to make a plot')
            %Parses inputs 
            p=inputParser();
            
            validateColor=@(x) assert(iscolor(x),...
                'Input must be a valid color. See iscolor function');
            addParameter(p,'Color','b',validateColor);
            
            validateMarker=@(x) assert(ismarker(x),...
                'Input must be a valid marker. See ismarker function');
            addParameter(p,'Marker','none',validateMarker);
            
            validateLine=@(x) assert(isline(x),...
                'Input must be a valid linestyle. See isline function');
            addParameter(p,'LineStyle','-',validateLine);
            
            addParameter(p,'MarkerSize',6,...
                @(x) validateattributes(x,{'numeric'},{'positive'}));
            addParameter(p,'make_labels',false,@islogical);
            
            interpreters={'none','tex','latex'};
            validateInterpreter=@(x) assert(contains(x,interpreters),...
                'Interpreter must be none, tex or latex');
            addParameter(p,'Interpreter','latex',validateInterpreter);
            parse(p,varargin{:});
            
            ind=findLineInd(this, plot_axes);
            if ~isempty(ind) && any(ind)
                set(this.hlines{ind},'XData',this.x,'YData',this.y);
            else
                this.hlines{end+1}=plot(plot_axes,this.x,this.y);
                ind=length(this.hlines);
            end
            
            %Sets the correct color and label options
            set(this.hlines{ind},'Color',p.Results.Color,'LineStyle',...
                p.Results.LineStyle,'Marker',p.Results.Marker,...
                'MarkerSize',p.Results.MarkerSize);
            
            if p.Results.make_labels
                interpreter=p.Results.Interpreter;
                xlabel(plot_axes,this.label_x,'Interpreter',interpreter);
                ylabel(plot_axes,this.label_y,'Interpreter',interpreter);
                set(plot_axes,'TickLabelInterpreter',interpreter);
            end
        end
        
        %If there is a line object from the trace in the figure, this sets
        %it to the appropriate visible setting.
        function setVisible(this, plot_axes, bool)
            if bool
                vis='on';
            else
                vis='off';
            end
            
            ind=findLineInd(this, plot_axes);
            if ~isempty(ind) && any(ind)
                set(this.hlines{ind},'Visible',vis)
            end
        end
        %Defines addition of two MyTrace objects
        function sum=plus(a,b)
            checkArithmetic(a,b);
            
            sum=MyTrace('x',a.x,'y',a.y+b.y,'unit_x',a.unit_x,...
                'unit_y',a.unit_y,'name_x',a.name_x,'name_y',a.name_y);
        end
        
        %Defines subtraction of two MyTrace objects
        function sum=minus(a,b)
            checkArithmetic(a,b);
            
            sum=MyTrace('x',a.x,'y',a.y-b.y,'unit_x',a.unit_x,...
                'unit_y',a.unit_y,'name_x',a.name_x,'name_y',a.name_y);
        end
        
        function [max_val,max_x]=max(this)
            assert(validatePlot(this),['MyTrace object must contain',...
                ' nonempty data vectors of equal length to find the max'])
            [max_val,max_ind]=max(this.y);
            max_x=this.x(max_ind);
        end
        
        function fwhm=calcFwhm(this)
            assert(validatePlot(this),['MyTrace object must contain',...
                ' nonempty data vectors of equal length to find the fwhm'])
            [max_val,~]=max(this);
            ind1=find(this.y>max_val/2,1,'first');
            ind2=find(this.y>max_val/2,1,'last');
            fwhm=this.x(ind2)-this.x(ind1);
        end
        
        %Integrates the trace numerically
        function area=integrate(this,varargin)
            assert(validatePlot(this),['MyTrace object must contain',...
                ' nonempty data vectors of equal length to integrate'])
            
            %Input parser for optional inputs
            p=inputParser;
            %Default is to use all the data in the trace
            addOptional(p,'ind',true(1,length(this.x)));
            parse(p,varargin{:});
            ind=p.Results.ind;
            
            %Integrates the data contained in the indexed part.
            area=trapz(this.x(ind),this.y(ind));
        end
        
        %Checks if the object is empty
        function bool=isempty(this)
            bool=isempty(this.x) && isempty(this.y);
        end
        
        %Checks if the data can be plotted
        function bool=validatePlot(this)
            bool=~isempty(this.x) && ~isempty(this.y)...
                && length(this.x)==length(this.y);
        end
        
        function hline=getLineHandle(this,ax)
            ind=findLineInd(this,ax);
            if ~isempty(ind)
                hline=this.hlines{ind}; 
            else
                hline=[];
            end
        end
    end
    
    methods (Access=private)
        %Checks if arithmetic can be done with MyTrace objects.
        function checkArithmetic(a,b)
            assert(isa(a,'MyTrace') && isa(b,'MyTrace'),...
                ['Both objects must be of type MyTrace to add,',...
                'here they are type %s and %s'],class(a),class(b));
            assert(strcmp(a.unit_x, b.unit_x) && strcmp(a.unit_y,b.unit_y),...
                'The MyTrace classes must have the same units for arithmetic');
            assert(length(a.x)==length(a.y) && length(a.x)==length(a.y),...
                'The length of x and y must be equal for arithmetic');
            assert(all(a.x==b.x),...
                'The MyTrace objects must have identical x-axis for arithmetic')
        end
        
        %Finds the hline handle that is plotted in the specified axes
        function ind=findLineInd(this, plot_axes)
            if ~isempty(this.hlines)
                ind=cellfun(@(x) ismember(x,findall(plot_axes,...
                    'Type','Line')),this.hlines);
            else
                ind=[];
            end
        end
    end
    
    %Set and get methods
    methods
        %Set function for x, checks if it is a vector of doubles.
        function set.x(this, x)
            assert(isnumeric(x),...
                'Data must be of class double');
            this.x=x(:);
        end
        
        %Set function for y, checks if it is a vector of doubles.
        function set.y(this, y)
            assert(isnumeric(y),...
                'Data must be of class double');
            this.y=y(:);
        end
        
        %Set function for name, checks if input is a string.
        function set.filename(this, name)
            assert(ischar(name),'Name must be a string, not a %s',...
                class(name));
            this.filename=name;
        end
        
        %Set function for unit_x, checks if input is a string.
        function set.unit_x(this, unit_x)
            assert(ischar(unit_x),'Unit must be a char, not a %s',...
                class(unit_x));
            this.unit_x=unit_x;
        end
        
        %Set function for unit_y, checks if input is a string
        function set.unit_y(this, unit_y)
            assert(ischar(unit_y),'Unit must be a char, not a %s',...
                class(unit_y));
            this.unit_y=unit_y;
        end
        
        %Set function for name_x, checks if input is a string
        function set.name_x(this, name_x)
            assert(ischar(name_x),'Name must be a char, not a %s',...
                class(name_x));
            this.name_x=name_x;
        end
        
        %Set function for name_y, checks if input is a string
        function set.name_y(this, name_y)
            assert(ischar(name_y),'Name must be a char, not a %s',...
                class(name_y));
            this.name_y=name_y;
        end
        
        function set.load_path(this, load_path)
            assert(ischar(load_path),'File path must be a char, not a %s',...
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
