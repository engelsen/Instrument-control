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
        %Information about how the trace was taken
        MeasHeaders=MyMetadata();
        load_path='';
        %Cell that contains handles the trace is plotted in
        hlines={};
        uid='';
    end
    
    properties (Access=private)
        Parser;
    end
    
    properties (Dependent=true)
        %Contains the MeasHeaders
        Metadata
        label_x;
        label_y;
    end
    methods (Access=private)
        %Creates the input parser for the class. Includes default values
        %for all optional parameters.
        function createParser(this)
            p=inputParser;
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'unit_x','x',@ischar);
            addParameter(p,'unit_y','y',@ischar);
            addParameter(p,'name_x','x',@ischar);
            addParameter(p,'name_y','y',@ischar);
            addParameter(p,'load_path','',@ischar);
            addParameter(p,'uid','',@ischar);
            addParameter(p,'MeasHeaders',MyMetadata(),...
                @(x) isa(x,'MyMetadata'));
            this.Parser=p;
        end
        
        %Sets the class variables to the inputs from the inputParser. Can
        %be used to reset class to default values if default_flag=true.
        function parseInputs(this, inputs, default_flag)
            parse(this.Parser,inputs{:});
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
            parseInputs(this,varargin,true);
            
            if ~ismember('load_path',this.Parser.UsingDefaults)
                loadTrace(this,this.load_path);
            end
        end
        
        %Defines the save function for the class. Note that this is only
        %used when we want to write only the data with its associated
        %trace, rather than just the trace. To write just the trace with
        %fewer input checks, use the writeTrace function.
        function save(this,varargin)
            %Parse inputs for saving
            p=inputParser;
            addParameter(p,'filename','placeholder',@ischar);
            addParameter(p,'save_dir',pwd,@ischar);
            addParameter(p,'save_prec',15);
            addParameter(p,'overwrite_flag',false);
            parse(p,varargin{:});
            
            %Assign shorter names
            filename=p.Results.filename;
            save_dir=p.Results.save_dir;
            save_prec=p.Results.save_prec;
            overwrite_flag=p.Results.overwrite_flag;
            %Puts together the full file name
            fullfilename=fullfile([save_dir,filename,'.txt']);
            
            %Creates the file in the given folder
            write_flag=createFile(save_dir,fullfilename,overwrite_flag);
            
            %Returns if the file is not created for some reason 
            if ~write_flag 
                error('File not created, returned write_flag %i',write_flag);
            end
            
            %We now write the data to the file
            writeData(this, fullfilename,'save_prec',save_prec);
        end
        
        %Writes the data to a file. This is separated so that other
        %programs can write to the file from the outside. We circumvent the
        %checks for the existence of the file here, assuming it is done
        %outside.
        function writeData(this,fullfilename, varargin)
            p=inputParser;
            addRequired(p,'fullfilename',@ischar);
            addParameter(p,'save_prec',15);
            parse(p,fullfilename,varargin{:});
            
            fullfilename=p.Results.fullfilename;
            save_prec=p.Results.save_prec;
            
            fileID=fopen(fullfilename,'a');


            
            %Writes the metadata header
            writeAllHeaders(this.Metadata,fullfilename);
            %Puts in header title for the data
            fprintf(fileID,...
                [this.Metadata.hdr_spec,'Data',this.Metadata.hdr_spec,'\r\n']);
            
            %Finds appropriate column width
            cw=max([length(this.label_y),length(this.label_x),...
                save_prec+7]);
            
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
            
            %Saves in scientific notation with correct column width defined
            %above. Again if cw=20, we get %14.10e\t%14.10e\r\n
            data_format_str=sprintf('%%%i.%ie\t%%%i.%ie\r\n',...
                cw,save_prec,cw,save_prec);
            fprintf(fileID,data_format_str,[this.x, this.y]');
            fclose(fileID);
        end
        
        function clearData(this)
            this.x=[];
            this.y=[];
        end
        
        function loadTrace(this, file_path, varargin)
            p=inputParser;
            addParameter(p,'hdr_spec','==',@ischar);
            addParameter(p,'end_header','Data',@ischar);
            parse(p,varargin{:});
            
            hdr_spec=p.Results.hdr_spec;
            end_header=p.Results.end_header;
            
            if ~exist(file_path,'file')
                error('File does not exist, please choose a different load path')
            end
            
            %Instantiate a header object from the file you are loading. We
            %get the line number we want to read from as an output.
            [MeasHeaders,end_line_no]=MyMetadata(...
                'load_path',file_path,...
                'hdr_spec',hdr_spec,...
                'end_header',end_header);
            
            %Tries to assign units and names
            try
                this.unit_x=MeasHeaders.TraceInformation.Unit1.value;
                this.unit_y=MeasHeaders.TraceInformation.Unit2.value;
                this.name_x=MeasHeaders.TraceInformation.Name1.value;
                this.name_y=MeasHeaders.TraceInformation.Name2.value;
            catch
                warning(['No metadata found. No units or labels assigned',...
                    ' when loading trace from %s'],file_path)
                this.name_x='x';
                this.name_y='y';
                this.unit_x='x';
                this.unit_y='y';
            end
            
            %Reads x and y data
            data_array=dlmread(file_path,'\t',end_line_no,0);
            this.x=data_array(:,1);
            this.y=data_array(:,2);
            
            this.load_path=file_path;
        end
        
        %Allows setting of multiple properties in one command.
        function setTrace(this, varargin)
            parseInputs(this, varargin, false);
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
            [~,~,fwhm,~]=findPeaks(this.y,this.x,'NPeaks',1);
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
        %Set function for MeasHeaders
        function set.MeasHeaders(this, MeasHeaders)
            assert(isa(MeasHeaders,'MyMetadata'),...
                ['MeasHeaders must be an instance of MyMetadata, ',...
                'it is %s'],class(MeasHeaders));
            this.MeasHeaders=MeasHeaders;
        end
        
        %Set function for x, checks if it is a vector of doubles.
        function set.x(this, x)
            assert(isnumeric(x),...
                'Data must be of class double');
            this.x=x(:);
        end
        
        %Set function for y, checks if it is a vector of doubles and
        %generates a new UID for the trace
        function set.y(this, y)
            assert(isnumeric(y),...
                'Data must be of class double');
            this.y=y(:);
            this.uid=genUid(); %#ok<MCSUP>
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
        
        function set.uid(this, uid)
            assert(ischar(uid),'UID must be a char, not a %s',...
                class(uid));
            this.uid=uid;
        end
        %Get function for label_x, creates label from name_x and unit_x.
        function label_x=get.label_x(this)
            label_x=sprintf('%s (%s)', this.name_x, this.unit_x);
        end
        
        %Get function for label_y, creates label from name_y and unit_y.
        function label_y=get.label_y(this)
            label_y=sprintf('%s (%s)', this.name_y, this.unit_y);
        end
        
        %Generates the full metadata of the trace
        function Metadata=get.Metadata(this)
            %First we update the trace information
            Metadata=MyMetadata();
            addField(Metadata,'Info');
            addParam(Metadata,'Info','uid',this.uid,'%s');
            addParam(Metadata,'Info','Name1',this.name_x,'%s');
            addParam(Metadata,'Info','Name2',this.name_y,'%s');
            addParam(Metadata,'Info','Unit1',this.unit_x,'%s');
            addParam(Metadata,'Info','Unit2',this.unit_y,'%s');
            
            addMetadata(Metadata,this.MeasHeaders);
        end
    end
end
