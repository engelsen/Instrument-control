% Convert textual representation of a Matlab expression to structure that 
% can be used by subsref and subsasgn functions  
function [varname, S] = str2substruct(str)
    % Match variable name
    vn = '^(?<varname>\w+)';           % pattern for base variable name
    name_re_out=regexp(str,vn,'match');
    
    % Check that the variable name had single match
    if length(name_re_out)==1
        varname=name_re_out{1};
    elseif length(name_re_out)>1
        error('Multiple matches are found for variable name.')
    else
        error('No matches are found for variable name.')
    end
    
    % Next match references to structure fields (or class properties), 
    % array indices and cell indices 
    
    % Define pattern to find comma-separated integers, possibly 
    % surrounded by white spaces
    csint = '(( *[0-9]+ *,)*( *[0-9]+ *))';
    
    aind = ['(?<arrind>\(',csint,'\))'];   % array index pattern
    cind = ['(?<cellind>{',csint,'})'];    % cell index pattern
    fn = '(?<fieldname>\.\w+)';            % field name pattern
    
    re_out=regexp(str,[fn,'|',aind,'|',cind],'names');
    
    type_cell=cell(1,length(re_out));
    subs_cell=cell(1,length(re_out));
    for i=1:length(re_out)
        if ~isempty(re_out(i).arrind)
            type_cell{i}='()';
            % Split, discarding the first and the last characters that are
            % braces, and then convert to numbers.
            char_ind=regexp(re_out(i).arrind(2:end-1),',','split');
            subs_cell{i}=num2cell(str2double(char_ind));
        elseif ~isempty(re_out(i).cellind)
            type_cell{i}='{}';
            % Split, discarding the first and the last characters that are
            % braces, and then convert to numbers.
            char_ind=regexp(re_out(i).cellind(2:end-1),',','split');
            subs_cell{i}=num2cell(str2double(char_ind));
        elseif ~isempty(re_out(i).fieldname)
            type_cell{i}='.';
            % remove '.' from the matched expression
            subs_cell{i}=re_out(i).fieldname(2:end);
        end
    end
    S=struct('type', type_cell, 'subs', subs_cell);
end

