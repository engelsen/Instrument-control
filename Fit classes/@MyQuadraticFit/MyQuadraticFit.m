classdef MyQuadraticFit < MyFit

    methods (Access = public)
        function this = MyQuadraticFit(varargin)
            this@MyFit(...
                'fit_name','Quadratic',...
                'fit_function','a*x^2+b*x+c',...
                'fit_tex','$$ax^2+bx+c$$',...
                'fit_params',{'a','b','c'},...
                'fit_param_names',{'Quadratic coeff.','Linear coeff.','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access = protected)
        
        %Overload the doFit function to do polyFit instead of nonlinear
        %fitting. 
        function fitted_vals = doFit(~, x, y, varargin)
            fitted_vals = polyfit(x, y, 2);
        end
    end   
end