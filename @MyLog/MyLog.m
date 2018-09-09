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
    end
    
    properties (SetAccess=public, GetAccess=public)    
        timestamps % Times at which data was aqcuired
        data % Cell array of measurements
        Headers % MyMetadata object to store labeled time marks
    end
    
    properties (Dependent=true)
        % Information about the log, including time labels and data headers
        Metadata    
        % Format specifier for one data line
        data_line_fmt
    end
    
    methods (Access=public)
        
        %% Constructo and destructor methods
        function this = MyLog(varargin)
            P=MyClassParser(this);
            P.KeepUnmatched=true;
            processInputs(P, this, varargin{:});
            
            this.Headers=MyMetadata(varargin{:});
            
            % Load the data from file if the file name was provided
            if ~ismember('file_name', P.UsingDefaults)
                loadLog(this);
            end
            
        end
        
        %% Save and load functionality
        % save the entire data record
        function saveLog(this, fname)
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
        function loadLog(this, fname)
            if nargin()<2
                fname=this.file_name;
            end
            
            [this.Headers, end_line_no]=MyMetadata('load_path',fname);
            
            % Read data as delimiter-separated values and convert to cell
            % array
            mdata = dlmread(filename, this.column_sep, end_line_no, 0);
            [m,~] = size(mdata);
            this.data = mat2cell(mdata, ones(1,m));
            
            if ismember('ColumnNames', this.Headers.field_names)
                cnames=structfun(@(x) x.value, this.Headers.ColumnNames,...
                    'UniformOutput', false);
                % The first column name is time, so skip it
                cnames(1)=[];
                % Assign the rest of the names to data headers
                for i=1:length(cnames)
                    this.data_headers{i}=cnames{i};
                end
                % Delete the field ColumnNames as it is generated
                % automatically when referring to Metadata and is not
                % supposed to be stored in the Headers
                deleteField(this.Headers, 'ColumnNames')
            end
        end
        
        
        %% Other functions
        
        % Append data point to the log
        function appendPoint(this, time, val, varargin)
            p=inputParser();
            addParameter(p, 'save', false, @islogical);
            parse(p, varargin{:});
            
            this.timestamps=[this.timestamps; time];
            this.data=[this.data; {val}];
            
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
            
            time_str=datestr(time);
            fieldname=genvarname('Lbl1', this.Headers.field_names);
            addField(this.Headers, fieldname);
            addParam(this.Headers, fieldname, 'time', time_str);
            
            % str can contain multiple lines, record them as separate
            % parameters
            [nlines,~]=size(str);
            for i=1:nlines
                strname=genvarname('str1',...
                    fieldnames(this.Headers.(fieldname)));
                addParam(this.Headers, fieldname, strname, str(i,:));
            end
        end
        
        % Plot the log data with time labels 
        function plotLog(this, Ax)
            if nargin()<2
                % If axes handle was not supplied, create new axes
                Ax = axes();
            else
                cla(Ax);
            end
            
            try
                mdata = cell2mat(this.data);
            catch
                warning(['Cannot display logger data, '...
                    'possibly because of data dimensions being different ',...
                    'at different times. Can try crlearing data to resolve.'])
                return
            end       
            hold(Ax,'on');
            [~, n] = size(mdata);
            % Plot data
            for i=1:n   
                plot(Ax, this.timestamps, mdata(:,i));
            end
            % Plot time labels
            hold(Ax,'off');
            % Add legend
            if n>=1 && ~isempty(this.data_headers{:})
                legend(Ax, this.data_headers{:},'Location','southwest');
                ylabel(Ax, app.y_label);
            end
        end
        
        function clearLog(this)
            this.timestamps = {};
            this.data = {};
            delete(this.Headers);
            this.Headers = MyMetadata();
        end
        
        % Check if data is suitable for plotting and saving as a list of
        % numerical vectors of equal length 
        function bool = isDataArray(this)
            % An empty cell array passes the test
            if isempty(this.data)
                bool = true;
                return
            end
            % Then check if all the elements are numeric vectors and have
            % the same length. Difference between columns and rows is
            % disregarded here. 
            l=length(this.data{1});
            bool = all(cellfun(@(x)(isreal(x)&&(length(x)==l)),this.data));
        end
    end
    
    %% set and get methods
    methods
        
        function data_line_fmt=get.data_line_fmt(this)
            cs=this.data_column_sep;
            nl=this.Headers.line_sep;
            
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
        
        function Metadata=get.Metadata(this)
            Metadata=copy(this.Headers);
            
            if ismember('ColumnNames', Metadata.field_names)
                deleteField(Metadata, 'ColumnNames')
            end
            addField(Metadata, 'ColumnNames');
            addParam(Metadata, 'ColumnNames', 'name1',...
                    'POSIX time (s)')
            for i=1:length(this.data_headers)
                tmpname = genvarname('name1',...
                    fieldnames(Metadata.ColumnNames));
                addParam(Metadata, 'ColumnNames', tmpname,...
                    this.data_headers{i})
            end
        end
    end
end

