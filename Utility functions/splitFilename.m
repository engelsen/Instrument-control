% Split filename into name and extension (if present), applying some more 
% elaborate procedure to determine the real extension than that used 
% in fileparts()

function [name, ext] = splitFilename(filename)
    filename_split = regexp(filename, '\.', 'split');
    
    if length(filename_split) == 1
        
        % No extension found
        name = filename;
        ext = '';
        return
    end
    
    % A candidate for the extension
    ext = filename_split{end};

    if ~isempty(ext) && ~any(isspace(ext)) && length(ext)<4 && ...
            ~all(ismember(ext(2:end), '0123456789'))
        
        % ext is actual extension
        % Add a point to conform with the convention of fileparts()
        ext = ['.' ext]; 
        name = strjoin(filename_split(1:end-1), '.');
    else
        
        % ext is not an actual extension 
        name = filename;
        ext = '';
    end
end

