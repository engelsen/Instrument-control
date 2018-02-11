% Read the header and first code line of a Matlab file, interpreting 
% 'property'='value' pairs indicated in comments
function Info = readCommentHeader(file_name)    
    Info = struct();
    Info.header = '';
    Info.first_code_line =''; 
    try
        fid = fopen(file_name,'r');
        % Read the file line by line, with a paranoid limitation on
        % the number of cycles 
        j = 1;
        while j<100000
            j=j+1;
            str = fgetl(fid);
            trimstr = strtrim(str);
            if isempty(trimstr)
                % An empty string
            elseif trimstr(1)=='%'
                % A comment string, try to extract the 'property'='value'
                % pair
                match = regexp(trimstr,'[%\s]*(\S*)\s*=(.*)','tokens');
                try
                    tag = lower(match{1}{1});
                    % Tags can be anything, except for the protected values
                    if ~isequal(tag, 'header') &&...
                            ~isequal(tag, 'first_code_line')
                        % Remove leading and trailing whitespaces with strtrim
                        Info.(tag) = strtrim(match{1}{2});
                    end
                catch
                end
            else 
                % Stop when the code begins
                Info.first_code_line = [str, newline];
                break
            end
            % Also store the header in its entirety
            Info.header = [Info.header, str, newline];
        end
        fclose(fid);
    catch
        warning('Could not read the file header of %s', file_name)
    end
end

