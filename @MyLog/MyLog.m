% Class to store data series versus time

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
        file_ext = '.log'
        
        file_name = '' % Used to save or load the data
        data_headers = {} % Cell array of column headers
        
        length_lim = Inf % Keep the log length below this limit
        
        % Information about the log in saveable format, 
        % including time labels and data headers
        Metadata 
    end
    
    properties (SetAccess=public, GetAccess=public)    
        timestamps % Times at which data was aqcuired
        data % Array of measurements
        TimeLabels % Structure array to store labeled time marks
        
        hlines={}; %Cell that contains handles the log is plotted in
    end
    
    properties (Dependent=true)   
        % Format specifier for one data line
        data_line_fmt
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
                'str',{},...        % message string
                'isdispl',{},...    % if this label is to be displayed
                'mark_arr',{},...   % array that representing plot marker
                'text_handle',{});  % handle to the plotted text object
            
            % Load the data from file if the file name was provided
            if ~ismember('file_name', P.UsingDefaults)
                load(this); %#ok<LOAD>
            end
            
        end
        
        %% Save and load functionality
        % save the entire data record or n_pt last points to file
        function save(this, fname, n_pt)
            % File name can be either supplied explicitly or given as the
            % file_name property
            if nargin()<2
                fname = this.file_name;
            end
            
            % Verify that the data can be saved
            assert(isDataArray(this),...
                ['Data cannot be reshaped into array, saving in '...
                'text format is not possible. You may try saving as ',...
                '.mat file instead.']);
            
            % Add file extension if it is not specified explicitly
            if ~ismember('.',fname)
                fname = [fname, this.file_ext];
            end
            
            try
            	createFile(fname);
                % Write time labels and column headers
                printAllHeaders(this.Metadata, fname);
                fid = fopen(fname,'a');
                % Write data body
                fmt=this.data_line_fmt;
                for i=1:length(this.timestamps)
                    fprintf(fid, fmt,...
                        posixtime(this.timestamps(i)), this.data{i});
                end
                fclose(fid);
            catch
                warning('Log was not saved');
                % Try closing fid in case it is still open
                try
                    fclose(fid);
                catch
                end
            end
        end
        
        
        % Save log header to file
        function load(this, fname)
            if nargin()<2
                fname=this.file_name;
            end
            
            [this.TimeLabels, end_line_no]=MyMetadata('load_path',fname);
            
            % Read data as delimiter-separated values and convert to cell
            % array
            mdata = dlmread(filename, this.column_sep, end_line_no, 0);
            [m,~] = size(mdata);
            this.data = mat2cell(mdata, ones(1,m));
            
            if ismember('ColumnNames', this.TimeLabels.field_names)
                cnames=structfun(@(x) x.value, this.TimeLabels.ColumnNames,...
                    'UniformOutput', false);
                % The first column name is time, so skip it
                cnames(1)=[];
                % Assign the rest of the names to data TimeLabels
                for i=1:length(cnames)
                    this.data_headers{i}=cnames{i};
                end
                % Delete the field ColumnNames as it is generated
                % automatically when referring to Metadata and is not
                % supposed to be stored in the TimeLabels
                deleteField(this.TimeLabels, 'ColumnNames')
            end
        end
        
        
        %% Other functions
        
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
                        printAllTimeLabels(this.Metadata, this.file_name);
                        fid = fopen(this.file_name,'a');
                    else
                        % otherwise open for appending
                        fid = fopen(this.file_name,'a');
                    end
                    fprintf(fid, this.data_line_fmt, posixtime(time), val);
                    fclose(fid);
                catch
                    warning(['Logger cannot save data at time = ',...
                        datestr(time)]);
                    % Try closing fid in case it is still open
                    try
                        fclose(fid);
                    catch
                    end
                end
            end
        end
        
        % Add label to the metadata
        function addTimeLabel(this, time, str)
            if nargin()<3
                % Invoke a dialog to add the label time and name
                answ = inputdlg({'Label text', 'Time'},'Add time label',...
                    [2 40; 1 40],{'',datestr(datetime('now'))});
                
                if isempty(answ)||isempty(answ{1})
                    return
                else
                    % Conversion of the inputed value to datetime to
                    % ensure proper format
                    time=datetime(answ{2});
                    str=answ{1};
                end
            end
            
            % Need to calculate length explicitly as using 'end' fails 
            % for empty array
            l=length(this.TimeLabels); 

            this.TimeLabels(l+1).time=time;
            this.TimeLabels(l+1).str=str;
            this.TimeLabels(l+1).isdispl=true;
            this.TimeLabels(l+1).mark_arr = calcTimeLabelLine(this, time);
        end
        
        % Plot the log data with time labels 
        function plot(this, Ax)
            if nargin()<2
                % If axes handle was not supplied, get current
                Ax = gca();
            end
            
            [~, ncols] = size(this.data);
            
            % Plot data
            pl_args=cell(1,2*ncols);
            for i=1:ncols   
                pl_args{2*i-1}=this.timestamps;
                pl_args{2*i}=this.data(:,i);
            end
            plot(Ax, pl_args{:});
            % Plot time labels
            lbl_names=this.TimeLabels.field_names;
            for i=1:length(lbl_names)
                t=datetime(this.TimeLabels.(lbl_names{i}).time.value);
                markline = calcTimeLabelLine(this, t);
                % Add line to plot
                plot(Ax, markline{:});
                % Add text label to plot
                str=this.TimeLabels.(lbl_names{i});
                txt_lbl=text(Ax, posixtime(t), 1, str);
            end
            % Resize the plot if necessary for all the labels to stay within
            % the plot area. Extent has format [left bottom width height]
            xmax=txt_lbl.Extent(1)+txt_lbl.Extent(3);
            ymax=txt_lbl.Extent(2)+txt_lbl.Extent(4);

            % Add legend
            if n>=1 && ~isempty(this.data_headers{:})
                legend(Ax, this.data_headers{:},'Location','northeastoutside');
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
            
            deleteAllFields(this.Metadata);
        end
        
        
        % Convert data cell array to matrix, which can be plotted or saved.
        % mdata is not implemented as dependent property as the situation
        % when data cannot be converted to matrix is considered normal.
        function [mdata, nrows, ncols] = dataToMat(this)
            try
                mdata = cell2mat(this.data);
            catch
                error('Log record cannot be converted to matrix.')
            end 
            
            % Ensure that each data array element is converted to a single
            % row
            [nrows, ncols] = size(mdata);
            assert(nrows==length(this.data),...
                ['Number or rows in concatenated data matrix is not ',...
                'consistent with the record length. Check that each ',...
                'data element contains a single row.']);
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
        
        function mark_arr = calcTimeLabelLine(this, time)
            % Define the extent of marker line to cover the data range
            % at the point nearest to the time label
            
            if isempty(this.timestamps)||this.timestamps(end)<time
                % If, for whatever reason, the time label is further in
                % future than the end of the time array, keep the mark
                % array undefined
                mark_arr=[];
            else
                % Otherwise calculate it to cover all data points at the
                % time of mark +/- 10%
                [~, ind] = min(this.timestamps-time);
                [mindat, maxdat]=minmax(this.data(ind,:));
                mark_arr={time, linspace(0.9*mindat, 1.1*maxdat, 10)};
            end
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
        
        function Mdt=get.Metadata(this)
            Mdt=this.Metadata;
            % Clear Metadata but preserve formatting
            clearFields(Mdt);
            
            % Add time labels
            addField(Mdt, 'TimeLabels');
            for i=1:length(this.TimeLabels)
                
            end
            
            % Add column names
            addField(Mdt, 'ColumnNames');
            addParam(Mdt, 'ColumnNames', 'Name1',...
                    'POSIX time (s)')
            for i=1:length(this.data_headers)
                tmpname = genvarname('Name1',...
                    fieldnames(Mdt.ColumnNames));
                addParam(Mdt, 'ColumnNames', tmpname,...
                    this.data_headers{i})
            end
        end
    end
end

