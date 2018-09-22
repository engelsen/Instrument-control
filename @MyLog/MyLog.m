% Class to store data series versus time
% Metadata for this class is stored independently

classdef MyLog < matlab.mixin.Copyable
    
    properties (Access=public)
        % Save time as posixtime up to ms precision
        time_fmt = '%14.3f'
        
        % Save data as reals with up to 14 decimal digits. Trailing zeros 
        % are removed by %g 
        data_fmt = '%.14g'
        
        % Data columns are separated by this symbol
        data_column_sep = '\t'
        
        % File extension that is appended by default when saving the log 
        % if a different one is not specified explicitly
        data_file_ext = '.log'
        
        % File extension for metadata
        meta_file_ext = '.meta'
        
        file_name = '' % Used to save or load the data
        data_headers = {} % Cell array of column headers
        
        length_lim = Inf % Keep the log length below this limit
    end
    
    properties (SetAccess=public, GetAccess=public)    
        timestamps % Times at which data was aqcuired
        data % Array of measurements
        TimeLabels % Structure array to store labeled time marks
        
        hlines={}; %Cell that contains handles the log is plotted in
        
        % Information about the log in saveable format, 
        % including time labels and data headers
        Metadata 
    end
    
    properties (Dependent=true)   
        data_line_fmt % Format specifier for one data line
        
        column_headers % Data headers + time header
        
        data_file_name % File name with extension for data saving
        meta_file_name % File name with extension for metadata saving
        
        timestamps_num % timestamps converted to numerical format
    end
    
    methods (Access=public)
        
        %% Constructo and destructor methods
        function this = MyLog(varargin)
            P=MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            this.Metadata=MyMetadata(P.unmatched_nv{:});
            
            % Create an empty structure array of time labels
            this.TimeLabels=struct(...
                'time',{},...       % datetime object
                'time_str',{},...   % time in text format
                'text_str',{},...   % message string
                'isdisp',{},...    % if this label is to be displayed
                'text_handles',{});  % handle to the plotted text object
            
            % Load the data from file if the file name was provided
            if ~ismember('file_name', P.UsingDefaults)
                load(this); %#ok<LOAD>
            end
            
        end
        
        %% Save and load functionality
        % save the entire data record 
        function save(this, fname)
            % Verify that the data can be saved
            assertDataMatrix(this);
            
            % File name can be either supplied explicitly or given as the
            % file_name property
            if nargin()<2
                fname = this.file_name;
            else
                this.file_name=fname;
            end
            
            assert(~isempty(fname), 'File name is not provided.');
            
            datfname=this.data_file_name;
            metfname=this.meta_file_name;
            
            stat=createFile(datfname);
            if stat
                % Save time labels in separate file
                save(this.Metadata, metfname, 'overwrite', true);

                fid = fopen(datfname,'w');
                printDataHeaders(this, datfname);
                % Write data body
                fmt=this.data_line_fmt;
                for i=1:length(this.timestamps)
                    fprintf(fid, fmt, this.timestamps_num(i), ...
                        this.data(i,:));
                end
                fclose(fid);
            end
        end
        
        
        % Load log from file
        function load(this, fname)
            if nargin()==2
                this.file_name=fname;
            end
            
            assert(~isempty(this.file_name), 'File name is not provided.');
            assert(exist(fname, 'file')==2, ['File ''',fname,...
                ''' is not found.'])
            
            % Load metadata if file is found
            if exist(this.meta_file_name, 'file')==2
                % Fields of Metadata are re-initialized by its get method, so
                % need to copy in order for the loaded information to be not
                % overwritten, on one hand, and on the other hand to use the
                % formatting defined by Metadata.
                M=copy(this.Metadata);
                load(M, this.meta_file_name);
            end
            
            % Convert time to datetime if needed
            fid=fopen(fname,'r');
            col_heads=strsplit(fgetl(fid),this.data_column_sep, ...
                'CollapseDelimiters', true);
            if length(col_heads)>=2
                this.data_headers=col_heads(2:end);
            end
            fclose(fid);
            
            % Read data as delimiter-separated values and convert to cell
            % array, skip the first line containing column headers
            fulldata = dlmread(fname, this.column_sep, 1, 0);
            
            this.data = fulldata(:,2:end);
            this.timestamps = fulldata(:,1);
            
            % Convert to datetime if the time column format is posixtime
            if ~isempty(col_heads) && ...
                    contains(col_heads{1},'posix','IgnoreCase',true)
                this.timestamps=datetime(this.timestamps, ...
                    'ConvertFrom','posixtime');
            end
            
            % Process metadata 
            if ismember('ColumnNames', M.field_names) && ...
                    length(M.ColumnNames.Name.value)>=2
                % Assign column headers from metadata here, 
                % possibly overwriting the ones found in the main file 
                this.data_headers=M.ColumnNames.Name.value(2:end);
            end
            if ismember('TimeLabels', M.field_names)
                Lbl=M.TimeLabels.Lbl.value;
                for i=1:length(Lbl)
                    this.TimeLabels(i).time_str=Lbl(i).time_str;
                    this.TimeLabels(i).time=datetime(Lbl(i).time_str);
                    this.TimeLabels(i).text_str=Lbl(i).text_str;
                end
            end      
        end
        
        %% Plotting
        
        % Plot the log data with time labels 
        function plot(this, varargin)
            % Verify that the data can be plotted
            assertDataMatrix(this);
            
            [~, ncols] = size(this.data);
            
            p=inputParser();
            addOptional(p, 'Ax', gca(), @(x)assert( ...
                isa(x,'axes')||isa(x,'uiaxes'),...
                'Argument must be axes or uiaxes.'));
            addParameter(p, 'time_labels', true, @islogical);
            addParameter(p, 'legend', true, @islogical);
            addParameter(p, 'isdisp', true(1,ncols), @(x) assert(...
                islogical(x) && isvector(x) && length(x)==ncols, ...
                ['''isdisp'' must be a logical vector of the size ',...
                'equal to the number of columns in data.']));
            parse(p, varargin{:});
            
            Ax=p.Results.Ax;
            isdisp=p.Results.isdisp;
            
            % Plot data
%             pl_args={};
%             for i=1:ncols
%                 if isdisp(i)
%                     pl_args=[pl_args, {this.timestamps}]; %#ok<AGROW>
%                     pl_args=[pl_args, {this.data(:,i)}]; %#ok<AGROW>
%                 end
%             end
%             plot(Ax, pl_args{:});
            Pls=line(Ax, this.timestamps, this.data);
            for i=1:ncols
                Pls(i).Visible=isdisp(i);
            end
            
            % Plot time labels and legend
            if (p.Results.time_labels)
                plotTimeLabels(this, Ax);
            end
            if (p.Results.legend)
                plotLegend(this, Ax);
            end

        end
        
        function plotTimeLabels(this, Ax)
            hold(Ax,'on')
            
            % Marker line for time labels spans over the entire plot
            yminmax=ylim(Ax);
            ymin=yminmax(1);
            ymax=yminmax(2);
            
            Ax.ClippingStyle='rectangle';
            markline = linspace(ymin, ymax, 2);
            for i=1:length(this.TimeLabels)
                t=this.TimeLabels(i);
                marktime = [t.time,t.time];
                if t.isdisp
                    % Add text label to plot, with 2% offset for beauty
                    str=t.text_str;
                    txt_h=text(Ax, t.time, 0.98*ymax, str,...
                        'HorizontalAlignment','right',...
                        'VerticalAlignment','bottom',...
                        'Rotation',90,...
                        'BackgroundColor','white',...
                        'Clipping','on',...
                        'Margin',1);
                    t.text_handles=[t.text_handles,txt_h];
                    % Add line to plot
                    plot(Ax, marktime, markline,'color','black');
                end
            end
            hold(Ax,'off')
        end
        
        function plotLegend(this, Ax)
             % Add legend
            if ~isempty(this.data_headers)
                legend(Ax, this.data_headers{:},'Location','northeastoutside');
            end
        end
        
        
        %% Manipulations with log data
        
        % Append data points to the log
        function appendData(this, time, val, varargin)
            p=inputParser();
            addParameter(p, 'save', false, @islogical);
            parse(p, varargin{:});
            
            % Format checks on the input data
            assert(isa(time,'datetime')||isnumeric(time),...
                ['''time'' argument must be numeric or ',...
                'of the class datetime.']);
            assert(iscolumn(time),'Time and array must be column');
            assert(ismatrix(val),['Value array must be matrix. ',...
                'Use cells to enclose arrays with more dimensions.'])
            [nrows, ~]=size(val);
            assert(length(time)==nrows,...
                'Lengths of the time and value arrays do not match');
            
            % Append new data and time stamps
            this.timestamps=[this.timestamps; time];
            this.data=[this.data; val];
            
            % Ensure the log length is within the length limit
            trim(this);
            
            % Optionally save the new data to file
            if p.Results.save
                try
                    exstat = exist(this.file_name,'file');
                    if exstat==0
                        % if the file does not exist, create it and write
                        % the metadata
                        createFile(this.file_name);
                        printAllHeaders(this.Metadata, this.file_name);
                        fid = fopen(this.file_name,'a');
                    else
                        % otherwise open for appending
                        fid = fopen(this.file_name,'a');
                    end
                    % Print new values to the file
                    for i=1:length(time)
                        fprintf(fid, this.data_line_fmt, ...
                            posixtime(time(i)), val(i));
                    end
                    fclose(fid);
                catch
                    warning(['Logger cannot save data at time = ',...
                        datestr(time(1))]);
                    % Try closing fid in case it is still open
                    try
                        fclose(fid);
                    catch
                    end
                end
            end
        end
        
        % Add label to the metadata
        function addTimeLabel(this, time, str, varargin)
            p=inputParser();
            addOptional(p, 'time', datetime('now'), ...
                @(x)assert(isa(x,'datetime'), ...
                '''time'' must be of the type datetime.'));
            addOptional(p, 'str', '', ...
                @(x) assert(iscellstr(x)||ischar(x)||isstring(x), ...
                '''str'' must be a string or cell array of strings.'));
            addParameter(p, 'save', false, @islogical);
            parse(p, varargin{:});
            
            if any(ismember({'time','str'}, p.UsingDefaults))
                % Invoke a dialog to add the label time and name
                answ = inputdlg({'Label text', 'Time'},'Add time label',...
                    [2 40; 1 40],{'',datestr(datetime('now'))});
                
                if isempty(answ)||isempty(answ{1})
                    return
                else
                    % Conversion of the inputed value to datetime to
                    % ensure proper format
                    time=datetime(answ{2});
                    str=cellstr(answ{1});
                end
            end
            
            % Need to calculate length explicitly as using 'end' fails 
            % for empty array
            l=length(this.TimeLabels); 

            this.TimeLabels(l+1).time=time;
            this.TimeLabels(l+1).time_str=datestr(time);
            this.TimeLabels(l+1).text_str=str;
            this.TimeLabels(l+1).isdisp=true;
            
            if p.Results.save==true
                % Save metadata with new time labels
                save(this.Metadata, this.meta_file_name, ...
                    'overwrite', true);
            end
        end
        
        % Clear log data and time labels
        function clear(this)
            % Clear with preserving the array type
            this.TimeLabels(:)=[];
            this.data_headers(:)=[];
            
            % Clear data and its type
            this.timestamps = [];
            this.data = [];
        end
        
        % Verify that the data can be saved or plotted
        function assertDataMatrix(this)
            assert(ismatrix(this.data)&&isnumeric(this.data),...
                ['Data is not a numeric matrix, saving in '...
                'text format is not possible.']);
        end
        
    end
    
    methods (Access=private)
        %% Auxiliary private functions
        
        % Ensure the log length is within length limit
        function trim(this)
            l=length(this.timestamps);
            if l>this.length_lim
                dn=l-this.length_lim;
                this.timestamps(1:dn)=[];
                this.data(1:dn)=[];
            end
        end
        
        % Print column names to file
        function printDataHeaders(this, fname)
            cs=this.data_column_sep;
            fid=fopen(fname, 'a');
            fprintf(['%s',cs], this.column_headers{:});
            fclose(fid);
        end
        
    end
    
    %% set and get methods
    methods
        
        function set.length_lim(this, val)
            assert(isreal(val),'''length_lim'' must be a real number');
            % Make length_lim non-negative and integer
            this.length_lim=max(0, round(val));
            % Apply the new length limit to log
            trim(this);
        end
        
        function set.data_headers(this, val)
            assert(iscellstr(val) && isrow(val), ['''data_headers'' must '...
                'be a row cell array of character strings.']) %#ok<ISCLSTR>
            this.data_headers=val;
        end
        
        % The get function for file_name adds extension if it is not
        % already present and also ensures proper file separators 
        % (by splitting and combining the file name)
        function fname = get.data_file_name(this)
            fname = this.file_name;
            [filepath,name,ext] = fileparts(fname);
            if isempty(ext)
                ext=this.data_file_ext;
            end
            fname = fullfile(filepath,[name,ext]);
        end
        
        function fname = get.meta_file_name(this)
            fname = this.file_name;
            [filepath,name,~] = fileparts(fname);
            ext=this.meta_file_ext;
            fname = fullfile(filepath,[name,ext]);
        end
        
        function data_line_fmt=get.data_line_fmt(this)
            cs=this.data_column_sep;
            nl=this.TimeLabels.line_sep;
            
            if isempty(this.data)
                l=0;
            else
                % Use end of the data array for better robustness when
                % appending a measurement
                l=length(this.data{end});
            end
            
            data_line_fmt = this.time_fmt;
            for i=1:l
                data_line_fmt = [data_line_fmt, cs, this.data_fmt]; %#ok<AGROW>
            end
            data_line_fmt = [data_line_fmt, nl];
        end
        
        function hdrs=get.column_headers(this)
            % Add header for the time column
            if isa(this.timestamps,'datetime')
                time_title_str = 'POSIX time (s)';
            else
                time_title_str = 'Time';
            end
            hdrs=[time_title_str,this.data_headers];
        end
        
        function time_num_arr=get.timestamps_num(this)
            % Convert time stamps to numbers
            if isa(this.timestamps,'datetime')
                time_num_arr=posixtime(this.timestamps);
            else
                time_num_arr=this.timestamps;
            end
        end
        
        function Mdt=get.Metadata(this)
            Mdt=this.Metadata;
            % Clear Metadata but preserve formatting
            clearFields(Mdt);
            
            % Add time labels (textual part of TimeLabels structure)
            addField(Mdt, 'TimeLabels');
            Lbl=struct('time_str', this.TimeLabels.time_str,...
                'text_str', this.TimeLabels.text_str);
            addParam(Mdt, 'TimeLabels', 'Lbl', Lbl)
            
            % Add column names
            addField(Mdt, 'ColumnNames');
            addParam(Mdt, 'ColumnNames', 'Name', this.column_headers)
        end
    end
end

