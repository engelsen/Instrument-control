classdef MyQuadraticFit < MyFit
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyQuadraticFit(varargin)
            this@MyFit(...
                'fit_name','Quadratic',...
                'fit_function','a*x^2+b*x+c',...
                'fit_tex','$$ax^2+bx+c$$',...
                'fit_params',{'a','b','c'},...
                'fit_param_names',{'Quadratic coeff.','Linear coeff.','Offset'},...
                varargin{:});
        end
        
    end
    
    methods (Access=protected)
        %Overload the doFit function to do polyFit instead of nonlinear
        %fitting. We here have the choice of whether to scale the data or
        %not.
        
        function doFit(this)
                this.coeffs=polyfit(this.Data.x,this.Data.y,2);
        end
    end   
end