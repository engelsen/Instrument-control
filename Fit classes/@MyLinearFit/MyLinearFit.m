classdef MyLinearFit < MyFit
    methods (Access = public)
        function this = MyLinearFit(varargin)
            this@MyFit(...
                'fit_name','Linear',...
                'fit_function','a*x+b',...
                'fit_tex','$$ax+bx$$',...
                'fit_params',{'a','b'},...
                'fit_param_names',{'Gradient','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access = protected)
        
        %Overload the doFit function to do polyFit instead of nonlinear
        %fitting
        function fitted_vals = doFit(~, x, y, varargin)
            fitted_vals = polyfit(x, y, 1);
        end
    end
end