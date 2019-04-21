% Read the header and first code line of a Matlab file, interpreting 
% 'property'='value' pairs indicated in comments

function Info = readCommentHeader(file_name)    
    
    % Parameter-value pairs found in the comment header are added as extra 
    % fields to this structure 
    Info = struct( ...
        'comment_header',   '', ...
        'first_code_line',  '' ...
        ); 
    
    fid = fopen(file_name,'r');

    while ~feof(fid)
        str = fgetl(fid);
        
        % Store the entire header
        Info.comment_header = [Info.comment_header, str, newline];
        
        trimstr = strtrim(str);
        if isempty(trimstr)

            % Skip empty strings
            continue
        elseif trimstr(1) == '%'

            % A comment string, try to extract the 'property'='value'
            % pair
            match = regexp(trimstr, '[%\s]*(\S*)\s*=(.*)', 'tokens');
            try
                tag = lower(match{1}{1});
                
                if ~ismember(tag, fieldnames(Info))
                    
                    % Remove leading and trailing whitespaces
                    val = strtrim(match{1}{2});

                    % Try converting to logical or double value
                    if strcmpi(val, 'true')
                        val = true;
                    elseif strcmpi(val, 'false')
                        val = false;
                    else
                        val = str2doubleHedged(val);
                    end

                    Info.ParamList.(tag) = val;
                end
            catch
            end
        else 

            % Stop when the code begins
            Info.first_code_line = [str, newline];
            break
        end
    end
    
    fclose(fid);
end

