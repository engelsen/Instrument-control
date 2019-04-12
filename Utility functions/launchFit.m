%Launcher for MyFit objects
function MyFitObj=launchFit(fit_name,varargin)
assert(ischar(fit_name),'fit_name input must be a char, currently it is a %s',...
    class(fit_name));

    switch lower(fit_name)
        case 'linear'
            MyFitObj=MyLinearFit(varargin{:});
        case 'quadratic'
            MyFitObj=MyQuadraticFit(varargin{:});
        case 'gaussian'
            MyFitObj=MyGaussianFit(varargin{:});
        case 'exponential'
            MyFitObj=MyExponentialFit(varargin{:});
        case 'lorentzian'
            MyFitObj=MyLorentzianFit(varargin{:});
        case 'doublelorentzian'
            MyFitObj=MyDoubleLorentzianFit(varargin{:});
        case 'gorodetsky2000'
            MyFitObj=MyGorodetksy2000Fit(varargin{:});
        otherwise
            error('%s is not a valid fit',fit_name);
    end
end