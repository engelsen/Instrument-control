% 

classdef MyLog < MyInputHandler
    
    properties (Access=public)
        % format specifiers for data saving and display
        time_fmt = '%14.3f' % Save time as posixtime up to ms precision
        
        % Save data as reals with 14 decimal digits. Trailing zeros 
        % are removed by %g 
        data_fmt = '%.14g'
        
        column_sep = '\t' % Data columns are separated by this symbol
        line_sep = '\r\n' % Line separator
        
        % File extension that is appended by default when saving the log 
        % if a different one is not specified explicitly
        file_ext = '.log'
        
        file_name = '' % Used to save or load the data
        data_headers = {} % Cell array of column headers
    end
    
    properties (SetAccess=public, GetAccess=public)
        timestamps % Times at which data was aqcuired
        data % Stored cell array of measurements
        time_labels % Structure array of named time marks 
    end
    
    methods (Access=public)
        
        %% Constructo and destructor methods
        function this = MyLog(varargin)
            %Parse input arguments with ConstructionParser and load them
            %into class properties
            this@MyInputHandler(varargin{:});
            
            % Define an empty array of time labels
            this.time_labels=struct('time',{},'str',{});
            
            % Load the data from file if the file name was provided
            if ~ismember('file_name',this.ConstructionParser.UsingDefaults)
                loadLog(this);
            end
            
        end
        
        function delete(this)
            fclose(this.file_name);
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
%             [~, m] = size(this.data);
%             % Check that 
%             try
%                 % Conversion to matrix is for dimensions verification only.
%                 l=length(this.data{1});
%                 cellfun(@(x)(isreal(x)&&length(x)==l),this.data);
%             catch
%                 warning(['Cannot convert the log data to matrix, saving in '...
%                     'text format is not possible. You may try saving as ',...
%                     '.mat file instead.'])
%                 return
%             end
            
            % Add file extension if it is not specified explicitly
            if ~ismember('.',fname)
                fname = [fname, this.file_ext];
            end
            
            try
            	createFile(fname);
                fid = fopen(fname,'w');
                % Write time labels and column headers
                printHeader(this, fid);
                
                % Write data body
                fmt_str = this.time_fmt;
                for i=1:m
                    fmt_str = [fmt_str, this.column_sep, this.data_fmt]; %#ok<AGROW>
                end
                fmt_str = [fmt_str, this.line_sep];
                
                for i=1:length(this.timestamps)
                    fprintf(fid, fmt_str,...
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
        
        % Print log header to the file, including time labels and column
        % headers
        function printHeader(this, fid)
            % write data headers to file if specified
            fprintf(fid, 'POSIX time [s]');
            for i=1:length(this.data_headers)
                fprintf(fid, ['%',this.data_field_width,'s'],...
                    this.data_headers{i});
            end
            fprintf(fid,'\r\n');
        end
        
        function loadLog(this, fname)
            if nargin()<2
                fname=this.file_name;
            end
            
            
        end
        
        %% Other functions
        
        % Append data point to the log
        function append(this, time, val, varargin)
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
                        % header names
                        createFile(this.file_name);
                        fid = fopen(this.file_name,'w');
                        writeColumnHeaders(this, fid);
                    else
                        % otherwise open for appending
                        fid = fopen(this.file_name,'a');
                    end
                    fprintf(fid, this.time_fmt, posixtime(time));
                    fprintf(fid, this.data_fmt, meas_result);
                    fprintf(fid,'\r\n');
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
        
        % Add time label
        function addLabel(this, time, str)
            if nargin()<3
                % Invoke a dilog to add the label time and name
                answ = inputdlg({'Time','Text'},'Add time label',...
                    [1 15],{datestr(datetime('now')),''});
                
                if isempty(answ)||isempty(answ{2})
                    return
                else
                    time=datetime(answ{1});
                    str=answ{2};
                end
            end
            this.time_labels(end+1)=struct();
            this.time_labels(end).time=time;
            this.time_labels(end).str=str;
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
            [~, m] = size(mdata);
            % Plot data
            for i=1:m   
                plot(Ax, this.timestamps, mdata(:,i));
            end
            % Plot time labels
            hold(Ax,'off');
            % Add legend
            if m>=1 && ~isempty(this.data_headers{:})
                legend(Ax, this.data_headers{:},'Location','southwest');
                ylabel(Ax, app.y_label);
            end
        end
        
        function clearLog(this)
            this.timestamps = {};
            this.data = {};
            this.time_labels = struct('time',{},'str',{});
        end
        
        % Create matrix from the cell array of data. Different from
        % cell2mat in that it ensures that the 
        function mdata = dataToMat(this)
            l=length(this.data);
            mdata=cell2mat(this.data);
            [n,~]=size(mdata);
            if n~=l
                reshape(mdata,[l,n/l])
            end
        end
    end
end

