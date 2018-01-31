function hCBar = hobjects( varargin )
% HOBJECTS  Return a default Graphics object array.
%    hobjects(N) returns a N-by-N matrix of default Graphics objects. 
% 
%    hobjects(M,N) or hobjects([M,N]) returns a M-by-N matrix of 
%    default Graphics objects.
% 
%    hobjects(M,N,P,...) or hobjects([M,N,P ...]) returns a 
%    M-by-N-by-P-by-... array of default Graphics objects.
% 
%    hobjects(SIZE(A)) creates an array of default Graphics objects 
%    and is the same size as A.
% 
%    hobjects with no arguments creates a 1-by-1 scalar default Graphics 
%    object.
% 
%    hobjects(0) with input of zero creates a 0-by-0 empty default Graphics 
%    object array.
% 
%    Note: The size inputs M, N, and P... should be nonnegative integers. 
%    Negative integers are treated as 0, and non-integers are truncated. 
% 
%    Example:
%       h = hobjects(2,3)      returns a 2-by-3 default Graphics object array
%       h = hobjects([1,2,3])  returns a 1-by-2-by-3 default Graphics object array
% 
%    See also: gobjects, graphics.Graphics, graphics.GraphicsPlaceholder.

% Copyright 2016 The MathWorks, Inc.

% Check inputs

switch nargin
	case 0
		% default: an 1-by-1 object
		siz = 1;
		
	case 1
		% check it is a vector of array dimensions
		assert(isnumeric(varargin{1}) && isrow(varargin{1}), 'hobjects:invalidinput', ...
			'Inputs must be scalar numeric or a vector of array dimensions.');
		siz = varargin{1};
		
	otherwise
		% check all inputs are scalar numeric
		for n=1:nargin
			assert(isnumeric(varargin{n}) && isscalar(varargin{n}), 'hobjects:invalidinput', ...
				'Inputs must be scalar numeric or a vector of array dimensions.');
		end
		siz = [varargin{:}];
end


% Create default Graphics object array

% a scalar object is expanded to n-by-n array
if isscalar(siz)
	siz = [siz siz];
end

% negative integers are treated as 0, and non-integers are truncated
siz = max(floor(siz),0);

% create the array
nel = prod(siz); % number of expected elements
if nel>0
	% create a full array
	hCBar(nel) = graphics.GraphicsPlaceholder;
	hCBar      = reshape(hCBar,siz);
else
	% create an empty array
	hCBar      = graphics.GraphicsPlaceholder.empty(siz);
end

end
