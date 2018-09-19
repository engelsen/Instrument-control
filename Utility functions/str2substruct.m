% Convert textual representation of a Matlab expression to structure that 
% can be used by subsref and subsasgn functions  

function [S, varname] = str2substruct(str)

    % Define patterns to match the variable name and subscript references, 
    % i.e. structure fields, array indices and cell indices 
    
    vn = '^(?<varname>[a-zA-Z]\w*)?';       % pattern for variable name
    
    % Expresion always returns one and only one match, which might be empty
    [re_tokens, re_rem]=regexp(str,vn,'tokens','split','once','emptymatch');
  
    varname=re_tokens{1};
    str=re_rem{2};
    
    % Pattern to find comma-separated integers, possibly 
    % surrounded by white spaces, which represent array indices
    csint = '(( *[:0-9]+ *,)*( *[:0-9]+ *))';
    
    % Define patterns to match subscript references, i.e. structure fields, 
    % array indices and cell indices 
    
    aind = ['\((?<arrind>',csint,')\)'];   % regular array index pattern
    cind = ['{(?<cellind>',csint,')}'];    % cell array index pattern
    fn = '\.(?<fieldname>\w+)';            % field name pattern
    
    [re_tokens, re_rem] = regexp(str, ...
        [fn,'|',aind,'|',cind],'names','split','emptymatch');
    
    % Check that the unmatched remainder of the expression is empty, 
    % i.e. that the expression has a proper format
    assert(all(cellfun(@(x)isempty(x),re_rem)), ['Expression ''',str,...
        ''' is not a valid subscript reference.']);
    
    type_cell=cell(1,length(re_tokens)-1);
    subs_cell=cell(1,length(re_tokens)-1);
    for i=1:length(re_tokens)
        if ~isempty(re_tokens(i).arrind)
            type_cell{i}='()';
            % Split and convert indices to numbers.
            char_ind=regexp(re_tokens(i).arrind,',','split');
            subs_cell{i}=cellfun(@str2doubleHedged, char_ind, ...
                'UniformOutput', false);
        elseif ~isempty(re_tokens(i).cellind)
            type_cell{i}='{}';
            % Split and convert indices to numbers.
            char_ind=regexp(re_tokens(i).cellind,',','split');
            subs_cell{i}=cellfun(@str2doubleHedged, char_ind, ...
                'UniformOutput', false);
        elseif ~isempty(re_tokens(i).fieldname)
            type_cell{i}='.';
            subs_cell{i}=re_tokens(i).fieldname;
        end
    end
    S=struct('type', type_cell, 'subs', subs_cell);
end

