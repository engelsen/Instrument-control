% Convert subreference structure S to readable format
function str = substruct2str(S, own_name)
    if nargin()<2
        own_name='';
    end
    
    str=own_name;
    
    for i=1:length(S)
        if S(i).type=='.'
            % Structure field
            str=[str,'.',S(i).subs]; %#ok<*AGROW>
        elseif strcmp(S(i).type,'()') || strcmp(S(i).type,'{}')
            % Array or cell array. Add opening bracket first.
            str=[str,S(i).type(1)];
            % Then print indices iterating over dimensions
            for j=1:length(S(i).subs)
                ind=S(i).subs{j};
                if length(ind)==1
                    % Single index or ':'
                    if ischar(ind)
                        str=[str,ind,','];
                    else
                        str=[str,sprintf('%i',ind),','];
                    end
                else
                    % Range of indices
                    str=[str, sprintf('%i',ind(1)), ...
                        ':',sprintf('%i',ind(end)),','];
                end
            end
            % Replace the last symbol, which is comma, with closing bracket
            str(end)=S(i).type(2);
        else
            error('Inknown indexing type: %s', S(i).type)
        end
    end
end

