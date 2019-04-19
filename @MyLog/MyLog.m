% Class to store data versus time.
% Data can be continuously appended and saved. It is possible to add
% labels (time marks) for particular moments in time. Data can be saved 
% and plotted with the time marks. 
% Metadata for this class is stored independently.
% If instantiated as MyLog(load_path) then 
% the content is loaded from file

classdef MyLog < matlab.mixin.Copyable
    
    properties (Access = public, SetObservable = true)
        
        % Save time as posixtime up to ms precision
        time_fmt = '%14.3f'
        
        % Save data as reals with up to 14 decimal digits. Trailing zeros 
        % are removed by %g 
        data_fmt = '%.14g'
        
        % Data column and line separators
        column_sep = '\t'
        line_sep = '\r\n'
        
        % File extension that is appended by default when saving the log 
        % if a different one is not specified explicitly
        data_file_ext = '.log'
        
        % File extension for metadata
        meta_file_ext = '.meta'
        
        % Formatting options for the metadata
        metadata_opts = {} 
        
        file_name = '' % Used to save or load the data
        data_headers = {} % Cell array of column headers
        
        length_lim = Inf % Keep the log length below this limit
        
        % Format for string representation of timestamps
        datetime_fmt = 'yyyy-MMM-dd HH:mm:ss'
    
        timestamps % Times at which data was aqcuired
        data % Array of measurements
        
        save_cont = false % If true changes are continuously saved
    end
       
    properties (GetAccess = public, SetAccess = protected, ...
            SetObservable = true)
        
        % Structure array that stores labeled time marks
        TimeLabels = struct( ...
            'time',     {}, ...  % datetime object
            'time_str', {}, ...  % time in text format
            'text_str', {});     % message string
        
        % Structure array that stores all the axes the log is plotted in
        PlotList = struct( ...
            'Axes',     {}, ...  % axes handles
            'DataLines',{}, ...  % data line handles
            'LbLines',  {}, ...  % label line handles
            'BgLines',   {});    % label line background handles 
    end
    
    properties (Dependent = true)
        channel_no      % Number of data colums
        
        data_line_fmt   % Format specifier for one data row to be printed
        
        column_headers  % Time column header + data column headers
        
        data_file_name  % File name with extension for data saving
        meta_file_name  % File name with extension for metadata saving
        
        timestamps_num  % Timestamps converted to numeric format
    end
    
    methods (Access = public)
        function this = MyLog(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        %% Save and load functionality
        % save the entire data record 
        function save(this, filename)
            
            % Verify that the data can be saved
            assertDataMatrix(this);
            
            % File name can be either supplied explicitly or given as the
            % file_name property
            if nargin() < 2
                filename = this.file_name;
            else
                this.file_name = filename;
            end
            
            assert(~isempty(filename), 'File name is not provided.');
            
            datfname = this.data_file_name;
            
            stat = createFile(datfname);
            if ~stat
                return
            end
            
            if ~isempty(this.TimeLabels)
                
                % Save time labels in a separate file
                saveMetadata(this);
            end

            fid = fopen(datfname, 'w');

            % Write column headers
            str = printDataHeaders(this);
            fprintf(fid, '%s', str);

            % Write the bulk of data
            fmt = this.data_line_fmt;
            for i = 1:length(this.timestamps)
                fprintf(fid, fmt, this.timestamps_num(i), this.data(i,:));
            end
            fclose(fid);
        end
        
        %% Plotting
        
        % Plot the log data with time labels. Reurns plotted line objects.  
        function Pls = plot(this, varargin)
            
            % Verify that the data is a numeric matrix, 
            % otherwise it cannot be plotted
            assertDataMatrix(this);
            
            [~, ncols] = size(this.data);
            
            p=inputParser();
            % Axes in which log should be plotted
            addOptional(p, 'Axes', [], @(x)assert( ...
                isa(x,'matlab.graphics.axis.Axes')||...
                isa(x,'matlab.ui.control.UIAxes'),...
                'Argument must be axes or uiaxes.'));
            
            % If time labels are to be displayed
            addParameter(p, 'time_labels', true, @islogical);
            
            % If legend is to be displayed
            addParameter(p, 'legend', true, @islogical);
            
            % Logical vector defining the data columns to be displayed
            addParameter(p, 'isdisp', true(1,ncols), @(x) assert(...
                islogical(x) && isvector(x) && length(x)==ncols, ...
                ['''isdisp'' must be a logical vector of the size ',...
                'equal to the number of data columns.']));
            
            % If 'reset' is true than all the data lines and time labels are
            % re-plotted with default style even if they are already present 
            % in the plot
            addParameter(p, 'reset', false, @islogical);
            
            parse(p, varargin{:});
            
            if ~isempty(p.Results.Axes)
                Axes = p.Results.Axes;
            else
                Axes = gca();
            end
            
            % Find out if the log was already plotted in these axes. If
            % not, appned Ax to the PlotList.
            ind = findPlotInd(this, Axes);
            if isempty(ind)
                l = length(this.PlotList);
                this.PlotList(l+1).Axes = Axes;
                ind = l+1;
            end
            
            % Plot data 
            if isempty(this.PlotList(ind).DataLines)
                
                % If the log was never plotted in Ax, 
                % plot using default style and store the line handles 
                Pls = line(Axes, this.timestamps, this.data);
                this.PlotList(ind).DataLines = Pls;
            else
                
                % Replace existing data
                Pls = this.PlotList(ind).DataLines;
                for i=1:length(Pls)
                    Pls(i).XData = this.timestamps;
                    Pls(i).YData = this.data(:,i);
                end
            end
            
            % Set the visibility of lines
            if ~ismember('isdisp', p.UsingDefaults)
                for i=1:ncols
                    Pls(i).Visible = p.Results.isdisp(i);
                end
            end
            
            if p.Results.time_labels
                
                % Plot time labels
                plotTimeLabels(this, Axes);
            else
                
                % Hide existing time labels
                try
                    set(this.PlotList(ind).LbLines, 'Visible', 'off');
                    set(this.PlotList(ind).BgLines, 'Visible', 'off');
                catch
                end
            end
            
            if (p.Results.legend)&&(~isempty(this.data_headers))&&...
                (~isempty(this.data)) 
            
                % Add legend only for for those lines that are displayed
                disp_ind = cellfun(@(x)strcmpi(x,'on'),{Pls.Visible});
                legend(Axes, Pls(disp_ind), this.data_headers{disp_ind},...
                    'Location','southwest');
            end
        end
        
        %% Manipulations with log data
        
        % Append data point to the log
        function appendData(this, time, val)
            
            % Format checks on the input data
            assert(isa(time,'datetime') || isnumeric(time),...
                ['''time'' argument must be numeric or ',...
                'of the class datetime.']);
            
            assert(isrow(val),'''val'' argument must be a row vector.');
            
            if ~isempty(this.data)
                [~, ncols] = size(this.data);
                assert(length(val) == ncols,['Length of ''val'' ' ...
                    'does not match the number of data columns']);
            end
            
            % Ensure time format
            if isa(time,'datetime')
                time.Format = this.datetime_fmt;
            end
            
            % Append new data and time stamps
            this.timestamps = [this.timestamps; time];
            this.data = [this.data; val];
            
            % Ensure the log length is within the length limit
            trim(this);
            
            % Optionally save the new data point to file
            if this.save_cont
                try
                    if exist(this.data_file_name, 'file') == 2
                        
                        % Otherwise open for appending
                        fid = fopen(this.data_file_name, 'a');
                    else
                        
                        % If the file does not exist, create it and write
                        % the column headers 
                        createFile(this.data_file_name);
                        fid = fopen(this.data_file_name, 'w');
                        
                        str = printDataHeaders(this);
                        fprintf(fid, '%s', str);
                    end
                    
                    % Convert the new timestamps to numeric form for saving
                    if isa(time,'datetime')
                        time_num = posixtime(time);
                    else
                        time_num = time;
                    end
                    
                    % Append new data points to file
                    fprintf(fid, this.data_line_fmt, time_num, val);
                    fclose(fid);
                catch
                    warning(['Logger cannot save data at time = ',...
                        datestr(datetime('now', ...
                        'Format',this.datetime_fmt))]);
                    
                    % Try closing fid in case it is still open
                    try
                        fclose(fid);
                    catch
                    end
                end
            end
        end
        
        %% Time labels 
        
        % Add label
        % Form with optional arguments: addTimeLabel(this, time, str)
        function addTimeLabel(this, varargin)
            p = inputParser();
            
            addOptional(p, 'time', ...
                datetime('now', 'Format', this.datetime_fmt), ...
                @(x)assert(isa(x,'datetime'), ...
                '''time'' must be of the type datetime.'));
            
            addOptional(p, 'str', '', ...
                @(x) assert(iscellstr(x)||ischar(x)||isstring(x), ...
                '''str'' must be a string or cell array of strings.'));
            
            parse(p, varargin{:});
            
            if any(ismember({'time', 'str'}, p.UsingDefaults))
                
                % Invoke a dialog to add the label time and name
                answ = inputdlg({'Label text', 'Time'},'Add time label',...
                    [2 40; 1 40],{'',datestr(p.Results.time)});
                
                if isempty(answ) || isempty(answ{1})
                    return
                else
                    
                    % Conversion of the inputed value to datetime to
                    % ensure proper format
                    time = datetime(answ{2}, 'Format', this.datetime_fmt);
                    
                    % Store multiple lines as cell array
                    str = cellstr(answ{1});
                end
            end
            
            this.TimeLabels(end+1).time = time;
            this.TimeLabels(end+1).time_str = datestr(time);
            this.TimeLabels(end+1).text_str = str;
            
            % Order time labels by ascending time
            sortTimeLabels(this);
            
            if this.save_cont
                saveMetadata(this);
            end
        end
        
        function deleteTimeLabel(this, ind)
            this.TimeLabels(ind) = [];
            
            if this.save_cont
                saveMetadata(this);
            end
        end
        
        % Modify text or time of an exising label. If new time and text are
        % not provided as arguments, modifyTimeLabel(this, ind, time, str), 
        % invoke a dialog.
        % ind - index of the label to be modified in TimeLabels array.
        function modifyTimeLabel(this, ind, varargin)
            p = inputParser();
            addRequired(p, 'ind', @(x)assert((rem(x,1)==0)&&(x>0), ...
                '''ind'' must be a positive integer.'));
            addOptional(p, 'time', ...
                datetime('now', 'Format', this.datetime_fmt), ...
                @(x)assert(isa(x,'datetime'), ...
                '''time'' must be of the type datetime.'));
            addOptional(p, 'str', '', ...
                @(x) assert(iscellstr(x)||ischar(x)||isstring(x), ...
                '''str'' must be a string or cell array of strings.'));
            parse(p, ind, varargin{:});
            
            if any(ismember({'time','str'}, p.UsingDefaults))
                Tlb=this.TimeLabels(ind);
                
                answ = inputdlg({'Label text', 'Time'}, ...
                    'Modify time label',...
                    [2 40; 1 40],{char(Tlb.text_str), Tlb.time_str});

                if isempty(answ)||isempty(answ{1})
                    return
                else
                    
                    % Convert the input value to datetime and ensure 
                    % proper format
                    time = datetime(answ{2}, 'Format', this.datetime_fmt);
                    
                    % Store multiple lines as cell array
                    str = cellstr(answ{1});
                end
            end
            
            this.TimeLabels(ind).time = time;
            this.TimeLabels(ind).time_str = datestr(time);
            this.TimeLabels(ind).text_str = str;
            
            % Order time labels by ascending time
            sortTimeLabels(this);
            
            if this.save_cont
                saveMetadata(this);
            end
        end
        
        % Show the list of labels in a readable format 
        function lst = printTimeLabels(this)
            
            % The returned output is a list of character strings
            lst = cell(length(this.TimeLabels), 1);
            
            for i=1:length(this.TimeLabels)
                if ischar(this.TimeLabels(i).text_str) ||...
                        isstring(this.TimeLabels(i).text_str)
                    tmpstr = this.TimeLabels(i).text_str;
                elseif iscell(this.TimeLabels(i).text_str)
                    
                    % If text is cell array, elements corresponding to 
                    % multiple lines, display the first line
                    tmpstr = this.TimeLabels(i).text_str{1};
                end
                lst{i} = [this.TimeLabels(i).time_str, ' ', tmpstr];
            end
        end
        
        %% Misc public functions
        
        % Clear log data and time labels
        function clear(this)
            
            % Clear while preserving the array types
            this.TimeLabels(:) = [];
            
            % Delete all the data lines and time labels
            for i=1:length(this.PlotList)
                delete(this.PlotList(i).DataLines);
                delete(this.PlotList(i).LbLines);
                delete(this.PlotList(i).BgLines);
            end
            this.PlotList(:) = [];
            
            % Clear data and its type
            this.timestamps = [];
            this.data = [];
            
            % Switch off continuous saving to prevent the overwriting of 
            % previously saved data
            this.save_cont = false;
        end
        
        % Verify that the data can be saved or plotted
        function assertDataMatrix(this)
            assert(ismatrix(this.data)&&isnumeric(this.data),...
                ['Data is not a numeric matrix, saving in '...
                'text format is not possible.']);
        end
    end
    
    methods (Access = public, Static = true)
        
        % Load log from file. Formatting parameters can be supplied as
        % varargin
        function L = load(filename, varargin)
            assert(exist(filename, 'file') == 2, ...
                ['File ''', filename, ''' is not found.'])
            
            L = MyLog(varargin{:});
            L.file_name = filename;
            
            % Load metadata if file is found
            if exist(L.meta_file_name, 'file') == 2
                Mdt = MyMetadata.load(L.meta_file_name,L.metadata_opts{:});
                setMetadata(L, Mdt);
            else
                disp(['Log metadata file is not found, continuing ' ...
                    'without it.']);
            end
            
            % Read column headers from the data file
            fid = fopen(filename,'r');
            dat_col_heads = strsplit(fgetl(fid), L.column_sep, ...
                'CollapseDelimiters', true);
            fclose(fid);
            
            % Assign column headers
            if length(dat_col_heads) > 1 
                L.data_headers = dat_col_heads(2:end);
            end
            
            % Read data as delimiter-separated values and convert to cell
            % array, skip the first line containing column headers
            fulldata = dlmread(filename, L.column_sep, 1, 0);
            
            L.data = fulldata(:, 2:end);
            L.timestamps = fulldata(:, 1);
            
            % Convert time stamps to datetime if the time column header
            % is 'posixtime'
            if ~isempty(dat_col_heads) && ...
                    contains(dat_col_heads{1}, 'posix', 'IgnoreCase', true)
                L.timestamps = datetime(L.timestamps, ...
                    'ConvertFrom', 'posixtime', 'Format', L.datetime_fmt);
            end
        end
    end
    
    methods (Access = protected)   
        function plotTimeLabels(this, Axes)
            
            % Find out if the log was already plotted in these axes
            ind = findPlotInd(this, Axes);
            if isempty(ind)
                l = length(this.PlotList);
                this.PlotList(l+1).Axes = Axes;
                ind = l+1;
            else
                Axes = this.PlotList(ind).Axes;
            end
            
            % Plot labels
            for i = 1:length(this.TimeLabels)
                T = this.TimeLabels(i);
                n_lines = max(length(T.text_str), 1);
                
                try
                    Lbl = this.PlotList(ind).LbLines(i);
                    
                    % Update the existing label line
                    Lbl.Value = T.time;
                    Lbl.Label = T.text_str;
                    Lbl.Visible = 'on';
                    
                    % Update the background width - font size times the
                    % number of lines
                    Bgl = this.PlotList(ind).BgLines(i);
                    Bgl.Value = T.time;
                    Bgl.LineWidth = Lbl.FontSize*n_lines;
                    Bgl.Visible = 'on';
                catch
                    
                    % Add new background line
                    this.PlotList(ind).BgLines(i) = xline(Axes, T.time, ...
                        'LineWidth',    10*n_lines, ...
                        'Color',        [1, 1, 1]);
                    
                    % Add new label line 
                    this.PlotList(ind).LbLines(i) = xline(Axes, T.time, ...
                        '-', T.text_str, ...
                        'LineWidth',                0.5, ...
                        'LabelHorizontalAlignment', 'center', ...
                        'FontSize',                 10);
                end
            end
            
            % Remove redundant markers if any
            n_tlbl = length(this.TimeLabels);
            
            if length(this.PlotList(ind).LbLines) > n_tlbl
                delete(this.PlotList(ind).LbLines(n_tlbl+1:end));
                this.PlotList(ind).LbLines(n_tlbl+1:end) = [];
            end
            
            if length(this.PlotList(ind).BgLines) > n_tlbl
                delete(this.PlotList(ind).BgLines(n_tlbl+1:end));
                this.PlotList(ind).BgLines(n_tlbl+1:end) = [];
            end
        end
        
        % Ensure the log length is within length limit
        function trim(this)
            len = length(this.timestamps);
            if len > this.length_lim
                
                % Remove data points beyond the length limit
                dn = len-this.length_lim;
                this.timestamps(1:dn) = [];
                this.data(1:dn) = [];
                
                % Remove the time labels which times fall outside the 
                % range of trimmed data
                BeginTime = this.timestamps(1);
                ind = [this.TimeLabels.time] < BeginTime;
                this.TimeLabels(ind) = [];
            end
        end
        
        % Print column names to a string
        function str = printDataHeaders(this)
            cs = this.column_sep;
            str = sprintf(['%s',cs], this.column_headers{:});
            str = [str, sprintf(this.line_sep)];
        end
        
        % Find out if the log was already plotted in the axes Ax and return
        % the corresponding index of PlotList if it was 
        function ind = findPlotInd(this, Ax)
            assert(isvalid(Ax),'Ax must be valid axes or uiaxes')
            
            if ~isempty(this.PlotList)
                ind_b=cellfun(@(x) isequal(x, Ax),{this.PlotList.Axes});
                % Find index of the first match
                ind=find(ind_b,1);
            else
                ind=[];
            end
        end
        
        % Re-order the elements of TimeLabels array so that labels 
        % corresponding to later times have larger index 
        function sortTimeLabels(this)
            times = [this.TimeLabels.time];
            [~,ind] = sort(times);
            this.TimeLabels = this.TimeLabels(ind);
        end
        
        % Create metadata from log properties
        function Mdt = getMetadata(this)
            
            if ~isempty(this.TimeLabels)
                
                % Add the textual part of TimeLabels structure
                Mdt = MyMetadata(this.metadata_opts{:}, ...
                    'title', 'TimeLabels');
            
                Lbl = struct('time_str', {this.TimeLabels.time_str}, ...
                    'text_str', {this.TimeLabels.text_str});
                addParam(Mdt, 'Lbl', Lbl);
            else
                Mdt = MyMetadata.empty();
            end
        end
        
        % Save log metadata, owerwriting existing
        function saveMetadata(this, Mdt)
            if exist('Mdt', 'var') == 0
                Mdt = getMetadata(this);
            end
            
            metfilename = this.meta_file_name;
            
            % Create or clear the file
            stat = createFile(metfilename, 'overwrite', true);
            if ~stat
                return
            end
            
            save(Mdt, metfilename);
        end
        
        % Process metadata
        function setMetadata(this, Mdt) 
            
            % Assign time labels
            Tl = titleref(Mdt, 'TimeLabels');
            if ~isempty(Tl)
                Lbl = Tl.ParamList.Lbl;
                for i=1:length(Lbl)
                    this.TimeLabels(i).time_str = Lbl(i).time_str;
                    this.TimeLabels(i).time = datetime(Lbl(i).time_str, ...
                        'Format', this.datetime_fmt);
                    this.TimeLabels(i).text_str = Lbl(i).text_str;
                end
            end 
        end
    end
    
    %% Set and get methods
    methods
        function set.length_lim(this, val)
            assert(isreal(val),'''length_lim'' must be a real number');
            
            % Make length_lim non-negative and integer
            this.length_lim = max(0, round(val));
            
            % Apply the new length limit to log
            trim(this);
        end
        
        function set.data_headers(this, val)
            assert(iscellstr(val) && isrow(val), ['''data_headers'' must '...
                'be a row cell array of character strings.']) %#ok<ISCLSTR>
            
            this.data_headers = val;
        end
        
        function set.save_cont(this, val)
            this.save_cont = logical(val);
        end
        
        % The get function for file_name adds extension if it is not
        % already present and also ensures proper file separators 
        % (by splitting and combining the file name)
        function fname = get.data_file_name(this)
            fname = this.file_name;
            [filepath,name,ext] = fileparts(fname);
            if isempty(ext)
                ext = this.data_file_ext;
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
            cs=this.column_sep;
            nl=this.line_sep;
            
            if isempty(this.data)
                l=0;
            else
                [~,l]=size(this.data);
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
        
        function val = get.channel_no(this)
            val = length(this.data_headers);
        end
    end
end

