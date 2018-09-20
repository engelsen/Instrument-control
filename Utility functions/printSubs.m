% Get valid subscripts for var as cell array.
%
% Example: if var is a structure row array with 2 elements, which have
% fields f1 and f2 the function returns 
% {'(1,1).f1','(1,1).f2','(1,2).f1','(1,2).f2'}
%
% If expansion_test is specified, the subscripts are only expanded if the 
% test is passed for subpart of var

function sn = printSubs(var, varargin)
    p=inputParser();
    % own_name is optionally prependend to the names of subs to create
    % full expressions that can be used to access parts of var
    addParameter(p, 'own_name', '', @(x) assert(...
        isvarname(x), '''own_name'' must be a valid variable name.'));
    addParameter(p, 'expansion_test', @(x)true, @(x) assert(...
        isa(x,'function_handle'), '''no_expand'' must be a function.'));
    parse(p, varargin{:});
    
    own_name=p.Results.own_name;
    exp_test=p.Results.expansion_test;
    
    sn={};
    if ~exp_test(var)
        % Do not expand if the test is not passed
        sn={''};
    elseif length(var)>1
        % Expand as array
        if iscell(var)
            % Cell array
            lbrace='{';
            rbrace='}';
        else
            % Regular array
            lbrace='(';
            rbrace=')';
        end
        
        % Create structure to address array elements depending on 
        % the brace type
        S.type=[lbrace,rbrace];
        S.subs={};
        
        % Create string for printing formatted indices
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
            tmp=printSubs(subsref(var,S),'expansion_test',exp_test);
            % Prepend array indices to the sub-part names
            tmp=cellfun(@(x)[ind_str, x], tmp, 'UniformOutput', false);
            sn=[sn; tmp]; %#ok<AGROW>
        end
    elseif isstruct(var)
        % Expand as structure
        fn = fieldnames(var);
        for i=1:length(fn)
            field_str=sprintf('.%s', fn{i});
            tmp=printSubs(var.(fn{i}),'expansion_test',exp_test);
            tmp=cellfun(@(x)[field_str, x], tmp, 'UniformOutput', false);
            sn=[sn; tmp]; %#ok<AGROW>
        end
    elseif iscell(var)&&length(var)==1
        % Expand as single cell
        tmp=printSubs(var{1},'expansion_test',exp_test);
        sn=cellfun(@(x)['{1}', x], tmp, 'UniformOutput', false);
    else
        % Do not expand
        sn={''};
    end
    
    % Optionally prepend the own name of var
    if ~isempty(own_name)
        sn=cellfun(@(x)[own_name, x], sn, 'UniformOutput', false);
    end
end

