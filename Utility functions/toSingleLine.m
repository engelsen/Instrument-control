% Remove carriage return and new line symbols from the string

function [new_str, is_modified] = toSingleLine(str, repl)
    if nargin() == 1
        repl = ' ';
    end
    
    newline_smb = {sprintf('\n'),sprintf('\r')}; %#ok<SPRINTFN>
    new_str = replace(str, newline_smb, repl);
    
    if nargout() > 1
        is_modified = ~strcmp(new_str, str);
    end
end

