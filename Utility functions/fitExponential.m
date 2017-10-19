function fitdata=fitExponential(x,y,varargin)

p=createFitParser(3);

parse(p,x,y,varargin{:});

%Converts to column vectors
x=p.Results.x(:);
y=p.Results.y(:);

assert(length(x)==length(y),'The length of x and y must be equal');

ffun='a*exp(b*x)+c';

fitdata=fit(x,y,ffun,'Lower',p.Results.Lower,'Upper',p.Results.Upper,...
    'StartPoint',p.Results.StartPoint);
end