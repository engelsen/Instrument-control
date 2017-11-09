function p=createFitParser(n_arg)
%Creates an input parser for a fit function with n_arg arguments. Default
%values are ones for initial parameters and plus and minus inf for upper
%and lower limits respectively. Ensures that the length is equal to the
%number of arguments.

p=inputParser;
validateStart=@(x) assert(isnumeric(x) && isvector(x) && length(x)==n_arg,...
    'Starting points must be given as a vector of size %d',n_arg);
validateLower=@(x) assert(isnumeric(x) && isvector(x) && length(x)==n_arg,...
    'Lower limits must be given as a vector of size %d',n_arg);
validateUpper=@(x) assert(isnumeric(x) && isvector(x) && length(x)==n_arg,...
    'Upper limits must be given as a vector of size %d',n_arg);

addOptional(p,'init_params',ones(1,n_arg),validateStart)
addOptional(p,'lower',-Inf*ones(1,n_arg),validateLower)
addOptional(p,'upper',Inf*ones(1,n_arg),validateUpper)

end