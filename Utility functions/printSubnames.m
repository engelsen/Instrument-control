% Get printed expressions for sub-elements of var as cell array. 
% Example: if var is a structure row array of 2 elements with fields
% f1 and f2 the function returns 
% {'(1,1).f1','(1,1).f2','(1,2).f1','(1,2).f2'}

function sn = printSubnames(var)
    sn={};
    if length(var)>1
        if iscell(var)
            % Expand as cell array
            lbrace='{';
            rbrace='}';
        else
            % Expand as regular array
            lbrace='(';
            rbrace=')';
        end
        
        % Create structure to address array elements depending on 
        % the braces type
        S.type=[lbrace,rbrace];
        S.subs={};
        
        % Create string for prinding formatted indices
        sz = size(var);
        ind_fmt=lbrace;
        for i=1:length(sz)
            ind_fmt=[ind_fmt,'%i,']; %#ok<AGROW>
        end
        ind_fmt(end)=rbrace;
        
        % Iterate over array elements
        ind=cell(1, length(sz));
        for i=1:numel(var)
            % Convert 1D to multi-dimensional index
            [ind{:}]=ind2sub(sz,i);
            ind_str=sprintf(ind_fmt, ind{:});
            % Index the variable according to the array type and
            % print the subnames of its element
            S.subs={i};
            tmp=printSubnames(subsref(var,S));
            % Prepend array indices to the sub-part names
            tmp=cellfun(@(x)[ind_str, x], tmp, 'UniformOutput', false);
            sn=[sn; tmp]; %#ok<AGROW>
        end
    elseif isstruct(var)
        % Expand as structure
        fn = fieldnames(var);
        for i=1:length(fn)
            field_str=sprintf('.%s', fn{i});
            tmp=printSubnames(var.(fn{i}));
            tmp=cellfun(@(x)[field_str, x], tmp, 'UniformOutput', false);
            sn=[sn; tmp]; %#ok<AGROW>
        end
    elseif iscell(var)&&length(var)==1
        % Expand as single cell
        tmp=printSubnames(var{1});
        sn=cellfun(@(x)['{1}', x], tmp, 'UniformOutput', false);
    else
        % Do not expand
        sn={''};
    end
        
end

