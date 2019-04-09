% Class for XY data representation with labelling, plotting and
% saving/loading functionality
% If instantiated as MyTrace(load_path) then 
% the content is loaded from file

classdef MyTrace < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
    properties (Access = public)
        x = []
        y = []
        
        name_x = 'x'
        name_y = 'y'
        unit_x = ''
        unit_y = ''
        
        file_name = ''
        
        % Structure storing MyMetadata objects with information about the 
        % trace was taken
        MeasHeaders = struct()
        
        % Formatting options for the metadata
        metadata_opts = {} 
        
        % Data formatting options
        column_sep  = '\t'      % Data column separator
        line_sep    = '\r\n'    % Data line separator
        data_sep    = 'Data'    % Separator between metadata and data
        save_prec   = 15        % Maximum digits of precision in saved data 
        
        % Cell that contains handles the trace is plotted in
        hlines = {}
    end
    
    properties (Dependent = true)        
        label_x
        label_y
    end
    
    methods (Access = public)
        function this = MyTrace(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        %Defines the save function for the class.
        function save(this, filename, varargin)
            
            % Parse inputs for saving
            p = inputParser;
            addParameter(p, 'overwrite', false);
            parse(p, varargin{:});
            
            assert(ischar(filename) && isvector(filename), ...
                    '''filename'' must be a character vector.')
            this.file_name = filename;
            
            % Create the file in the given folder
            stat = createFile(filename, 'overwrite', p.Results.overwrite);
            
            % Returns if the file is not created for some reason 
            if ~stat
                warning('File not created, returned write_flag %i.', stat);
                return
            end

            % Create metadata header
            MdtS = getMetadata(this);
            
            % Convert to array, set unified formatting and save 
            Mdt = structfun(@(x)x, MdtS);
            
            if ~isempty(this.metadata_fmt)
                set(Mdt, this.metadata_fmt{:});
            end
            save(Mdt, filename);
            
            % Write the data
            fileID = fopen(filename,'a');
            
            % Pads the vectors if they are not equal length
            diff = length(this.x)-length(this.y);
            if diff<0
                this.x = [this.x; zeros(-diff,1)];
                warning(['Zero padded x vector as the saved vectors ' ...
                    'are not of the same length']);
            elseif diff>0
                this.y = [this.y; zeros(diff,1)];
                warning(['Zero padded y vector as the saved vectors ' ...
                    'are not of the same length']);
            end
            
            % Save data in the more compact of fixed point and scientific 
            % notation with trailing zeros removed.
            % If save_prec=15, we get %.15g\t%.15g\r\n
            % Formatting without column padding may look ugly but it 
            % signigicantly reduces the file size.
            data_format_str = ...
                sprintf(['%%.%ig', this.column_sep, '%%.%ig', ...
                this.line_sep], this.save_prec, this.save_prec);
            
            fprintf(fileID, data_format_str, [this.x, this.y]');
            fclose(fileID);
        end
        
        function clearData(this)
            this.x = [];
            this.y = [];
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
        function setVisible(this, Axes, bool)
            if bool
                vis='on';
            else
                vis='off';
            end
            
            ind=findLineInd(this, Axes);
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
            n0 = ceil(n/2);
            
            if nargin()==3 && (strcmpi(opt,'average')||strcmpi(opt,'avg'))
                
                % Compute moving average with 'shrink' option so that the
                % total number of samples is preserved. Endpoints will be
                % discarded by starting the indexing from n0.
                tmpy = movmean(this.y, 'Endpoints', 'shrink');
                
                this.x = this.x(n0:n:end);
                this.y = tmpy(n0:n:end);
            else
                
                % Downsample without averaging
                this.x = this.x(n0:n:end);
                this.y = this.y(n0:n:end);
            end
        end
        
        %Checks if the object is empty
        function bool = isDataEmpty(this)
            bool = isempty(this.x) && isempty(this.y);
        end
        
        %Checks if the data can be plotted
        function bool = validatePlot(this)
            bool =~isempty(this.x) && ~isempty(this.y)...
                && length(this.x)==length(this.y);
        end
        
        function hline = getLineHandle(this,ax)
            ind=findLineInd(this,ax);
            if ~isempty(ind)
                hline=this.hlines{ind}; 
            else
                hline=[];
            end
        end
    end
    
    methods (Access = public, Static = true)
        
        % Load trace from file
        function Trace = load(filename, varargin)
            assert(exist(filename, 'file'), ['File does not exist, ' ...
                'please choose a different load path.'])
            
            % Extract data formatting 
            p = inputParser();
            p.KeepUnmatched = true;
            addParameter(p, 'FormatSource', {}, @(x) isa(x,'MyTrace'));
            addParameter(p, 'metadata_opts', {}, @iscell);
            parse(p, varargin{:});
            
            if ~ismember('FormatSource', p.UsingDefaults)
                Fs = p.Results.FormatSource;
                
                % Take formatting from the source object
                mdt_opts = Fs.metadata_opts;
                trace_opts = { ...
                    'column_sep',    Fs.column_sep, ...
                    'line_sep',      Fs.line_sep, ...
                    'data_sep',      Fs.data_sep, ...
                    'save_prec',     Fs.save_prec, ...
                    'metadata_opts', Fs.metadata_opts};
            else
                
                % Formatting is either default or was suppled explicitly
                mdt_opts = p.Results.metadata_opts;
                trace_opts = varargin;
            end
            
            % Load metadata and convert from array to structure
            [Mdt, n_end_line] = MyMetadata.load(filename, mdt_opts{:});
            MdtS = arrToStruct(Mdt);
            
            if isfield(MdtS, 'Info') && isparam(MdtS.Info, 'Type')
                class_name = MdtS.Info.Type;
            else
                class_name = 'MyTrace';
            end
            
            % Instantiate an appropriate type of Trace
            Trace = feval(class_name, trace_opts{:});
            
            setMetadata(Trace, MdtS);
            
            % Reads x and y data
            data_array = dlmread(filename, Trace.column_sep, n_end_line,0);
            Trace.x = data_array(:,1);
            Trace.y = data_array(:,2);
            
            Trace.file_name = filename;
        end
    end
    
    methods (Access = protected)
        
        % Generate metadata that includes measurement headers and
        % information about trace. This function is used in place of 'get'
        % method so it can be overloaded in a subclass.
        function MdtS = getMetadata(this)
            MdtS = this.MeasHeaders;
            
            % Add a field with the information about the trace
            Info = MyMetadata('title', 'Info');
            addParam(Info, 'Type',   class(this));
            addParam(Info, 'Name1',  this.name_x);
            addParam(Info, 'Name2',  this.name_y);
            addParam(Info, 'Unit1',  this.unit_x);
            addParam(Info, 'Unit2',  this.unit_y);
            
            MdtS.Info = Info;
            
            % Add a separator for the bulk of trace data
            DataSep = MyMetadata('title', this.data_sep);
            
            MdtS.DataSep = DataSep;
        end
        
        % Load metadata into the trace
        function setMetadata(this, MdtS)
            if isfield(MdtS, 'Info')
                if isparam(MdtS.Info, 'Unit1')
                    this.unit_x = MdtS.Info.Unit1;
                end
                
                if isparam(MdtS.Info, 'Unit2')
                    this.unit_y = MdtS.Info.Unit2;
                end
                
                if isparam(MdtS.Info, 'Name1')
                    this.name_x = MdtS.Info.Name1;
                end
                
                if isparam(MdtS.Info, 'Name2')
                    this.name_y = MdtS.Info.Name2;
                end
                
                % Remove the metadata containing trace properties 
                MdtS = rmfield(MdtS, 'Info');
            else
                warning(['No trace metadata found. No units or labels ' ...
                    'assigned when loading trace from %s.'], filename);
            end
            
            if isfield(MdtS, this.data_sep)
                
                % Remove the empty data separator field
                MdtS = rmfield(MdtS, this.data_sep);
            end
            
            % Store the remainder under measurement headers
            this.MeasHeaders = MdtS;
        end
        
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
        function ind = findLineInd(this, Axes)
            if ~isempty(this.hlines)
                ind = cellfun(@(x) ismember(x, findall(Axes, ...
                    'Type','Line')), this.hlines);
            else
                ind = [];
            end
        end
    end
    
    %Set and get methods
    methods
        %Set function for MeasHeaders
        function set.MeasHeaders(this, Val)
            assert(isstruct(Val),...
                'MeasHeaders must be a structure of MyMetadata objects');
            this.MeasHeaders = Val;
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
