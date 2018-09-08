% 

classdef MyLog < MyInputHandler
    
    properties (Access=public)
        % format specifiers for data saving and display
        time_fmt = '%14.3f' % Save time as posixtime up to ms precision
        data_field_width = '24'
        data_fmt = '%24.14e' % Save data as reals with 14 decimal digits
        % Format for displaying last reading label: value
        disp_fmt = '%15s: %.2e'
        
        save_file
        data_headers = {} % Cell array of column headers
    end
    
    properties (SetAccess=protected, GetAccess=public)
        timestamps % Times at which data was aqcuired
        data % Stored cell array of measurements
        time_lbls % Time labels 
    end
    
    methods (Access=public)
        function this = MyLog(varargin)
        end
        
        % save the entire data record
        function saveLog(this)
            try
            	createFile(this.save_file);
                fid = fopen(this.save_file,'w');
                writeColumnHeaders(this, fid);
                for i=1:length(this.timestamps)
                    fprintf(fid, this.time_fmt,...
                        posixtime(this.timestamps(i)));
                    fprintf(fid, this.data_fmt,...
                        this.data{i});
                    fprintf(fid,'\r\n');
                end
                fclose(fid);
            catch
                warning('Data was not saved');
                % Try closing fid in case it is still open
                try
                    fclose(fid);
                catch
                end
            end
        end
        
        function loadLog(this)
        end
        
        % Append data point to the log
        function appendPoint(this, val)
        end
        
        
        function addTimeLabel(this)
        end
        
        % Plot the log data with time labels 
        function plotLog(this, axes)
        end
        
        function clearLog(this)
            this.timestamps = [];
            this.data = [];
        end
               
        function printColumnHeaders(this, fid)
            % write data headers to file if specified
            fprintf(fid, 'POSIX time [s]');
            for i=1:length(this.data_headers)
                fprintf(fid, ['%',this.data_field_width,'s'],...
                    this.data_headers{i});
            end
            fprintf(fid,'\r\n');
        end
        
    end
end

