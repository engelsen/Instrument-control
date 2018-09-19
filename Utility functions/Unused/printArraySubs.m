% Print subscripts of array

function sn = printArraySubs(arr, varargin)
    p=inputParser();
    % own_name is optionally prependend to the names of subs to create
    % full expressions that can be used to access parts of var
    addParameter(p, 'own_name', '', @(x) assert(...
        isvarname(x), '''own_name'' must be a valid variable name.'));
    addParameter(p, 'contract_dims', 0, @(x) assert(...
        isnumeric(x) && mod(x,1)==0 && x>0,...
        '''contract_dims'' must be a positive integer.'));
    parse(p, varargin{:});
    
    ncdim=p.Results.contract_dims;
    own_name=p.Results.own_name;

    % Create string for printing formatted indices
    sz = size(arr);
    
    % Number of expanded dimensions
    nedim=length(sz)-ncdim;
    
    if nedim<1 || all(sz(1:nedim)==1)
        % Do not expand if all dimensions are contracted or have only the
        % size of 1
        sn={own_name};
        return
    end
    
    ind_fmt='(';
    for i=1:nedim
        ind_fmt=[ind_fmt,'%i,']; %#ok<AGROW>
    end
    for i=1:ncdim
        ind_fmt=[ind_fmt,':,']; %#ok<AGROW>
    end
    ind_fmt(end)=')';
    
    % Number of non-contracted indices
    nind=prod(sz(1:nedim));
    sn=cell(nind,1);
    % Iterate over array elements
    ind=cell(1, length(sz));
    for i=1:prod(sz(1:nedim))
        % Convert 1D to multi-dimensional index
        [ind{:}]=ind2sub(sz,i);
        ind_str=sprintf(ind_fmt, ind{1:nedim});
        sn{i}=[own_name,ind_str]; 
    end

end

