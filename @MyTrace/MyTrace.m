% Class for XY data representation with labelling, plotting and
% saving/loading functionality
% If instantiated as MyTrace(load_path) then 
% the content is loaded from file

classdef MyTrace < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
    properties (Access=public)
        x=[];
        y=[];
        name_x='x';
        name_y='y';
        unit_x='';
        unit_y='';
        % MyMetadata storing information about how the trace was taken
        MeasHeaders
        file_name='';
        
        % Data column and line separators
        column_sep = '\t'
        line_sep='\r\n'
        
        %Cell that contains handles the trace is plotted in
        hlines={};
    end
    
    properties (Dependent=true)        
        label_x
        label_y
    end
    
    methods (Access=public)
        function this=MyTrace(varargin)
            P=MyClassParser(this);
            % options for MeasHeaders
            addParameter(P, 'metadata_opts',{},@iscell);
            
            if mod(length(varargin),2)==1
                % odd number of elements in varargin - interpret the first
                % element as file name and the rest as name-value pairs
                load_path=varargin{1};
                assert(ischar(load_path)&&isvector(load_path),...
                    '''file_name'' must be a vector of characters');
                processInputs(P, this, varargin{2:end});
                this.file_name=load_path;
            else
                % Parse varargin as a list of name-value pairs 
                processInputs(P, this, varargin{:});
                load_path=[];
            end
            
            this.MeasHeaders=MyMetadata(P.Results.metadata_opts{:});
            
            if ~isempty(load_path)
                load(this, load_path);
            end
        end
        
        %Defines the save function for the class. Note that this is only
        %used when we want to write only the data with its associated
        %trace, rather than just the trace. To write just the trace with
        %fewer input checks, use the writeData function.
        function save(this, varargin)
            %Parse inputs for saving
            p=inputParser;
            addParameter(p,'save_prec',15);
            addParameter(p,'overwrite',false);
            
            if mod(length(varargin),2)==1
                % odd number of elements in varargin - interpret the first
                % element as file name and the rest as name-value pairs
                fname=varargin{1};
                assert(ischar(fname)&&isvector(fname),...
                    '''filename'' must be a vector of characters');
                this.file_name=fname;
                parse(p,varargin{2:end});
            else
                % Parse varargin as a list of name-value pairs and take
                % file name from the class property
                fname=this.file_name;
                parse(p,varargin{:});
            end
            
            %Creates the file in the given folder
            stat=createFile(fname, 'overwrite', p.Results.overwrite);
            
            %Returns if the file is not created for some reason 
            if stat
                %We now write the data to the file
                writeData(this, fname, 'save_prec', p.Results.save_prec);
            else
                warning('File not created, returned write_flag %i',stat);
            end
            
        end
        
        %Writes the data to a file. This is separated so that other
        %programs can write to the file from the outside. We circumvent the
        %checks for the existence of the file here, assuming it is done
        %outside.
        function writeData(this, fullfilename, varargin)
            p=inputParser;
            addRequired(p,'fullfilename',@ischar);
            addParameter(p,'save_prec',15);
            parse(p,fullfilename,varargin{:});
            
            fullfilename=p.Results.fullfilename;
            save_prec=p.Results.save_prec;

            %Writes the metadata header
            Mdt=makeMetadata(this);
            save(Mdt, fullfilename);
            
            fileID=fopen(fullfilename,'a');
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
            
            %Save in the more compact of fixed point and scientific 
            %notation with trailing zeros removed
            %If save_prec=15, we get %.15g\t%.15g\r\n
            %Formatting without column padding may look ugly but makes
            %files significantly smaller
            data_format_str=sprintf(['%%.%ig',this.column_sep,'%%.%ig',...
                this.line_sep],save_prec,save_prec);
            fprintf(fileID, data_format_str,[this.x, this.y]');
            fclose(fileID);
        end
        
        function clearData(this)
            this.x=[];
            this.y=[];
        end
        
        function load(this, file_path, varargin)
            p=inputParser;
            addParameter(p,'hdr_spec',...
                this.MeasHeaders.hdr_spec,@ischar);
            addParameter(p,'end_header',...
                this.MeasHeaders.end_header,@ischar);
            parse(p,varargin{:});
            
            this.MeasHeaders.hdr_spec=p.Results.hdr_spec;
            this.MeasHeaders.end_header=p.Results.end_header;
            
            if ~exist(file_path,'file')
                error('File does not exist, please choose a different load path')
            end
            
            %Read metadata. We get the line number we want to read
            %the main data from as an output.
            end_line_no=load(this.MeasHeaders, file_path);
            
            %Tries to assign units and names and then delete the Info field
            %from MeasHeaders
            try
                setFromMetadata(this, this.MeasHeaders);
                deleteField(this.MeasHeaders,'Info');
            catch
                warning(['No trace metadata found. No units or labels ',...
                    'assigned when loading trace from %s'],file_path)
                this.name_x='x';
                this.name_y='y';
                this.unit_x='';
                this.unit_y='';
            end
            
            %Reads x and y data
            data_array=dlmread(file_path, this.column_sep, ...
                end_line_no,0);
            this.x=data_array(:,1);
            this.y=data_array(:,2);
            
            this.file_name=file_path;
        end
        
        % Generate metadata that includes measurement headers and
        % information about trace. This function is used in place of 'get'
        % method so it can be overloaded in a subclass.
        function Mdt=makeMetadata(this)
            %First we update the trace information
            Mdt=MyMetadata();
            addField(Mdt,'Info');
            addParam(Mdt,'Info','Name1',this.name_x);
            addParam(Mdt,'Info','Name2',this.name_y);
            addParam(Mdt,'Info','Unit1',this.unit_x);
            addParam(Mdt,'Info','Unit2',this.unit_y);
            
            addMetadata(Mdt,this.MeasHeaders);
        end
        % Assign trace parameters from metadata
        function setFromMetadata(this, Mdt)
            if isfield(Mdt.Info, 'Unit1')
                this.unit_x=Mdt.Info.Unit1.value;
            end
            if isfield(Mdt.Info, 'Unit2')
                this.unit_y=Mdt.Info.Unit2.value;
            end
            if isfield(Mdt.Info, 'Name1')
                this.name_x=Mdt.Info.Name1.value;
            end
            if isfield(Mdt.Info, 'Name2')
                this.name_y=Mdt.Info.Name2.value;
            end
        end
        

        %Plots the trace on the given axes, using the class variables to
        %define colors, markers, lines and labels. Takes all optional
        %parameters of the class as inputs.
        function plot(this, varargin)
            % Do nothing if there is no data in the trace
            if isempty(this)
                return
            end
            
            %Checks that x and y are the same size
            assert(validatePlot(this),...
                'The length of x and y must be identical to make a plot')
            %Parses inputs 
            p=inputParser();
            
            % Axes in which log should be plotted
            addOptional(p, 'plot_axes', [], @(x)assert( ...
                isa(x,'matlab.graphics.axis.Axes')||...
                isa(x,'matlab.ui.control.UIAxes'),...
                'Argument must be axes or uiaxes.'));
            
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
            
            %If axes are not supplied get current
            if ~isempty(p.Results.plot_axes)
                plot_axes=p.Results.plot_axes;
            else
                plot_axes=gca();
            end
            
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
        function sum=plus(this,b)
            checkArithmetic(this,b);
            
            sum=MyTrace('x',this.x,'y',this.y+b.y, ...
                'unit_x',this.unit_x,'unit_y',this.unit_y, ...
                'name_x',this.name_x,'name_y',this.name_y);
        end
        
        %Defines subtraction of two MyTrace objects
        function diff=minus(this,b)
            checkArithmetic(this,b);
            
            diff=MyTrace('x',this.x,'y',this.y-b.y, ...
                'unit_x',this.unit_x,'unit_y',this.unit_y, ...
                'name_x',this.name_x,'name_y',this.name_y);
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
            [~,~,fwhm,~]=findpeaks(this.y,this.x,'NPeaks',1);
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
        
        % Picks every n-th element from the trace,
        % performing a running average first if opt=='avg'
        function downsample(this, n, opt)
            n0=ceil(n/2);
            if nargin()==3 && (strcmpi(opt,'average') || strcmpi(opt,'vg'))
                % Compute moving average with 'shrink' option so that the
                % total number of samples is preserved. Endpoints will be
                % discarded by starting the indexing from n0.
                tmpy=movmean(this.y, 'Endpoints', 'shrink');
                
                this.x=this.x(n0:n:end);
                this.y=tmpy(n0:n:end);
            else
                % Downsample without averaging
                this.x=this.x(n0:n:end);
                this.y=this.y(n0:n:end);
            end
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
        function checkArithmetic(this, b)
            assert(isa(this,'MyTrace') && isa(b,'MyTrace'),...
                ['Both objects must be of type MyTrace to add,',...
                'here they are type %s and %s'],class(this),class(b));
            assert(strcmp(this.unit_x, b.unit_x) && ...
                strcmp(this.unit_y,b.unit_y),...
                'The MyTrace classes must have the same units for arithmetic')
            assert(length(this.x)==length(this.y)==...
                length(this.x)==length(this.y),...
                'The length of x and y must be equal for arithmetic');
            assert(all(this.x==b.x),...
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
        
        %Set function for x, checks if it is a vector of doubles and
        %reshapes into a column vector
        function set.x(this, x)
            assert(isnumeric(x),...
                'Data must be of class double');
            this.x=x(:);
        end
        
        %Set function for y, checks if it is a vector of doubles and
        %reshapes into a column vector
        function set.y(this, y)
            assert(isnumeric(y),...
                'Data must be of class double');
            this.y=y(:);
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
        
        function set.file_name(this, file_name)
            assert(ischar(file_name),'File path must be a char, not a %s',...
                class(file_name));
            this.file_name=file_name;
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
