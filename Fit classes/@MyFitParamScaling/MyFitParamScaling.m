% Class that adds the capability of normalizing the data by z-score before
% performing the fit to improve numeric performance. 
% Scaling/unscaling functions for the parameters must be defined in 
% the end classes.

classdef (Abstract) MyFitParamScaling < MyFit
    
     methods (Access = public)
        function this = MyFitParamScaling(varargin)
            this@MyFit(varargin{:});
        end
     end
     
    methods (Access = protected)
        
        % Overload the doFit function to fit scaled data.
        function fitted_vals = doFit(this, x, y, init_vals, lim_lower, ...
                lim_upper)
            
            % Scale x and y data
            [scaled_x, mean_x, std_x] = zscore(x);
            [scaled_y, mean_y, std_y] = zscore(y);
            
            % Scaling coefficients
            sc = {mean_x, std_x, mean_y, std_y};
            
            scaled_fitted_vals = doFit@MyFit(this, scaled_x, scaled_y, ...
                scaleFitParams(this, init_vals, sc), ...
                scaleFitParams(this, lim_lower, sc), ...
                scaleFitParams(this, lim_upper, sc));
            
            fitted_vals = unscaleFitParams(this, scaled_fitted_vals, sc);
        end
    end
    
    methods (Access = protected, Abstract)
        
        % Functions that define scaling and unscaling of the fit parameters
        % by zscore
        sc_vals = scaleFitParams(~, vals, xy_zscore)
        
        vals = unscaleFitParams(~, sc_vals, xy_zscore)
    end
end

