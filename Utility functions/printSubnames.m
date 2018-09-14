% Get printed expressions for sub-elements of var as cell array. 
% Example: if var is a structure array of 2 elements with single fields f1
% and f2 the function returns 
% {'(1).f1','(1).f2','(2).f1','(2).f2'}

function sn = printSubnames(var)
    sn={};
    if iscell(var)
        % Expand as cell array
        arrsz = size(var);
        ind_str='{';
        for i=1:length(arrsz)
            ind_str=[ind_str,'%i,']; %#ok<AGROW>
        end
        ind_str(end)='}';
        
        
        for i=1:length(ind_list)
            ind_str=sprintf(ind_str, ind_list{i});
            tmp=printSubnames(var{ind_list{i}});
            tmp=cellfun(@(x)[ind_str, x], tmp, 'UniformOutput', false);
            sn=[sn; tmp]; %#ok<AGROW>
        end
    elseif length(var)>1
        % Expand as array
        for i=1:length(var)
            ind_str=sprintf('(%i)',i);
            tmp=printSubnames(var(i));
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
    else
        % Do not expand
        sn={''};
    end
        
end

