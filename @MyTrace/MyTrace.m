% Class for XY data representation with labelling, plotting and
% saving/loading functionality

classdef MyTrace < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
    properties (Access = public)
        x = []
        y = []
        
        name_x = 'x'
        name_y = 'y'
        unit_x = ''
        unit_y = ''
        
        file_name = ''
        
        % Array of MyMetadata objects with information about the trace. 
        % The full metadata also contains information about the trace 
        % properties like units etc.  
        UserMetadata = MyMetadata.empty() 
        
        % Formatting options for the metadata
        metadata_opts = {} 
        
        % Data formatting options
        column_sep  = '\t'      % Data column separator
        line_sep    = '\r\n'    % Data line separator
        data_sep    = 'Data'    % Separator between metadata and data
        save_prec   = 15        % Maximum digits of precision in saved data 
    end
    
    properties (GetAccess = public, SetAccess = protected, ...
            NonCopyable = true)
        
        % Cell that contains the handles of Line objects the trace 
        % is plotted in
        PlotLines = {}
    end
    
    properties (Dependent=true)        
        label_x
        label_y
    end
    
    methods (Access = public)
        function this = MyTrace(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        function delete(this)
            
            % Delete lines from all the axes the trace is plotted in
            cellfun(@delete, this.PlotLines);
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
            Mdt = getMetadata(this);
            
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
            if isDataEmpty(this)
                return
            end
            
            % Checks that x and y are the same size
            assert(validateData(this),...
                'The length of x and y must be identical to make a plot')
            
            % Parses inputs 
            p = inputParser();
            p.KeepUnmatched = true;
            
            % Axes in which the trace should be plotted
            addOptional(p, 'Axes', [], @(x)assert(isaxes(x),...
                'Argument must be axes or uiaxes.'));
            
            addParameter(p, 'make_labels', true, @islogical);
            
            validateInterpreter = @(x) assert( ...
                ismember(x, {'none', 'tex', 'latex'}),...
                'Interpreter must be none, tex or latex');
            addParameter(p, 'Interpreter', 'latex', validateInterpreter);
            
            parse(p, varargin{:});
            
            line_opts = struct2namevalue(p.Unmatched);
            
            %If axes are not supplied get current
            if ~isempty(p.Results.Axes)
                Axes = p.Results.Axes;
            else
                Axes = gca();
            end
            
            ind = findLineInd(this, Axes);
            
            if ~isempty(ind) && any(ind)
                set(this.PlotLines{ind}, 'XData', this.x, 'YData', this.y);
            else
                this.PlotLines{end+1} = plot(Axes, this.x, this.y);
                ind = length(this.PlotLines);
            end
            
            % Sets the correct color and label options
            if ~isempty(line_opts)
                set(this.PlotLines{ind}, line_opts{:});
            end
            
            if p.Results.make_labels
                makeLabels(this, Axes, p.Results.Interpreter)
            end
        end
        
        % Add labels to the axes
        function makeLabels(this, Axes, interpreter)
            if exist('interpreter', 'var') == 0
                interpreter = 'latex';
            end
            
            xlabel(Axes, this.label_x, 'Interpreter', interpreter);
            ylabel(Axes, this.label_y, 'Interpreter', interpreter);
            set(Axes, 'TickLabelInterpreter', interpreter);
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
                set(this.PlotLines{ind},'Visible',vis)
            end
        end
        
        %Defines addition of two MyTrace objects
        function Sum=plus(this,b)
            checkArithmetic(this,b);
            
            Sum=MyTrace('x',this.x,'y',this.y+b.y, ...
                'unit_x',this.unit_x,'unit_y',this.unit_y, ...
                'name_x',this.name_x,'name_y',this.name_y);
        end
        
        %Defines subtraction of two MyTrace objects
        function Diff=minus(this,b)
            checkArithmetic(this,b);
            
            Diff=MyTrace('x',this.x,'y',this.y-b.y, ...
                'unit_x',this.unit_x,'unit_y',this.unit_y, ...
                'name_x',this.name_x,'name_y',this.name_y);
        end
        
        function [max_val,max_x]=max(this)
            assert(validateData(this),['MyTrace object must contain',...
                ' nonempty data vectors of equal length to find the max'])
            [max_val,max_ind]=max(this.y);
            max_x=this.x(max_ind);
        end
        
        function fwhm=calcFwhm(this)
            assert(validateData(this),['MyTrace object must contain',...
                ' nonempty data vectors of equal length to find the fwhm'])
            [~,~,fwhm,~]=findpeaks(this.y,this.x,'NPeaks',1);
        end
        
        function [mean_x,std_x,mean_y,std_y]=calcZScore(this)
            mean_x=mean(this.x);
            std_x=std(this.x);
            mean_y=mean(this.y);
            std_y=std(this.y);
        end
        
        % Integrates the trace numerically. Two possible ways to call the
        % function:
        %
        % integrate(Trace)              - integrate the entire data
        % integrate(Trace, xmin, xmax)  - integrate over [xmin, xmax]
        % integrate(Trace, ind)         - integrate data with indices ind
        function area = integrate(this, varargin)
            assert(validateData(this), ['MyTrace object must contain',...
                ' nonempty data vectors of equal length to integrate'])
            
            switch nargin()
                case 1
                
                    % The function is called as integrate(Trace), integrate
                    % the entire trace
                    xvals = this.x;
                    yvals = this.y;
                case 2
            
                    % The function is called as integrate(Trace, ind)
                    ind = varargin{1};
                    xvals = this.x(ind);
                    yvals = this.y(ind);
                case 3
                    
                    % The function is called as integrate(Trace,xmin,xmax)
                    xmin = varargin{1};
                    xmax = varargin{2};
                    
                    % Select all data points within the integration range
                    ind = (this.x > xmin) & (this.x < xmax);
                    xvals = this.x(ind);
                    yvals = this.y(ind);
                    
                    % Add the two points corresponding to the interval ends
                    % if the interval is within data range
                    if xmin >= this.x(1)
                        yb = interp1(this.x, this.y, xmin);
                        xvals = [xmin; xvals];
                        yvals = [yb; yvals];
                    end
                    
                    if xmax <= this.x(end)
                        yb = interp1(this.x, this.y, xmax);
                        xvals = [xvals; xmax];
                        yvals = [yvals; yb];
                    end
                otherwise
                    error(['Unrecognized function signature. Check ' ...
                        'the function definition to see acceptable ' ...
                        'input argument.'])
            end
            
            % Integrates the data using the trapezoidal method
            area = trapz(xvals, yvals);
        end
        
        % Picks every n-th element from the trace,
        % performing a running average first if opt=='avg'
        function downsample(this, n, opt)
            n0 = ceil(n/2);
            
            if exist('opt', 'var') && ...
                    (strcmpi(opt,'average') || strcmpi(opt,'avg'))
                
                % Compute moving average with 'shrink' option so that the
                % total number of samples is preserved. Endpoints will be
                % discarded by starting the indexing from n0.
                tmpy = movmean(this.y, n, 'Endpoints', 'shrink');
                
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
        
        %Checks if the data can be processed as a list of {x, y} values, 
        %e.g. integrated over x or plotted
        function bool = validateData(this)
            bool =~isempty(this.x) && ~isempty(this.y)...
                && length(this.x)==length(this.y);
        end
        
        function Line = getLine(this, Ax)
            ind = findLineInd(this, Ax);
            if ~isempty(ind)
                Line = this.PlotLines{ind}; 
            else
                Line = [];
            end
        end
    end
    
    methods (Access = public, Static = true)
        
        % Load trace from file
        function Trace = load(filename, varargin)
            assert(exist(filename, 'file') ~= 0, ['File does not ' ...
                'exist, please choose a different load path.'])
            
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
            
            Info = titleref(Mdt, 'Info');
            if ~isempty(Info) && isparam(Info, 'Type')
                class_name = Info.ParamList.Type;
            else
                class_name = 'MyTrace';
            end
            
            % Instantiate an appropriate type of Trace
            Trace = feval(class_name, trace_opts{:});
            
            setMetadata(Trace, Mdt);
            
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
        function Mdt = getMetadata(this)
            
            % Make a field with the information about the trace
            Info = MyMetadata('title', 'Info');
            addParam(Info, 'Type',   class(this));
            addParam(Info, 'Name1',  this.name_x);
            addParam(Info, 'Name2',  this.name_y);
            addParam(Info, 'Unit1',  this.unit_x);
            addParam(Info, 'Unit2',  this.unit_y);
            
            % Make a separator for the bulk of trace data
            DataSep = MyMetadata('title', this.data_sep);
            
            Mdt = [Info, this.UserMetadata, DataSep];
            
            % Ensure uniform formatting
            if ~isempty(this.metadata_opts)
                set(Mdt, this.metadata_opts{:});
            end
        end
        
        % Load metadata into the trace
        function setMetadata(this, Mdt)
            
            Info = titleref(Mdt, 'Info');
            if ~isempty(Info)
                if isparam(Info, 'Unit1')
                    this.unit_x = Info.ParamList.Unit1;
                end
                
                if isparam(Info, 'Unit2')
                    this.unit_y = Info.ParamList.Unit2;
                end
                
                if isparam(Info, 'Name1')
                    this.name_x = Info.ParamList.Name1;
                end
                
                if isparam(Info, 'Name2')
                    this.name_y = Info.ParamList.Name2;
                end
                
                % Remove the metadata containing trace properties 
                Mdt = rmtitle(Mdt, 'Info');
            else
                warning(['No trace metadata found. No units or labels ' ...
                    'assigned when loading trace from %s.'], filename);
            end
            
            % Remove the empty data separator field
            Mdt = rmtitle(Mdt, this.data_sep);
            
            % Store the remainder as user metadata
            this.UserMetadata = Mdt;
        end
        
        %Checks if arithmetic can be done with MyTrace objects.
        function checkArithmetic(this, b)
            assert(isa(this,'MyTrace') && isa(b,'MyTrace'),...
                ['Both objects must be of type MyTrace ,',...
                'here they are type %s and %s'],class(this),class(b));
            
            assert(strcmp(this.unit_x, b.unit_x) && ...
                strcmp(this.unit_y,b.unit_y),...
                'The trace objects do not have the same units')
            
            assert(length(this.x)==length(this.y), ['The length of x ' ...
                'and y in the first argument are not equal']);
            
            assert(length(b.x)==length(b.y), ['The length of x and y ' ...
                'in the second argument are not equal']);
            
            assert(all(this.x==b.x),...
                'The trace objects do not have identical x-axis ')
        end
        
        % Finds the hline handle that is plotted in the specified axes
        function ind = findLineInd(this, Axes)
            if ~isempty(this.PlotLines)
                ind = cellfun(@(x) ismember(x, findall(Axes, ...
                    'Type','Line')), this.PlotLines);
            else
                ind = [];
            end
        end
        
        % Overload the standard copy() method to create a deep copy, 
        % i.e. when handle properties are copied recursively
        function Copy = copyElement(this)
            Copy = copyElement@matlab.mixin.Copyable(this);
            
            % Copy metadata
            Copy.UserMetadata = copy(this.UserMetadata);
        end
    end
    
    %% Set and get methods
    
    methods
        function set.UserMetadata(this, Val)
            assert(isa(Val, 'MyMetadata'),...
                'UserMetadata must be an array of MyMetadata objects');
            this.UserMetadata = Val;
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
