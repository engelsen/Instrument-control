classdef MyExponentialFit < MyFit
    
    methods (Access = public)
        function this = MyExponentialFit(varargin)
            this@MyFit( ...
                'fit_name',         'Exponential',...
                'fit_function',     'a*exp(b*x)+c',...
                'fit_tex',          '$$ae^{bx}+c$$',...
                'fit_params',       {'a','b','c'},...
                'fit_param_names',  {'Amplitude','Rate','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access = protected)
        
        %Overload the doFit function to do scaled fits.
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
        
        function calcInitParams(this)
            ind=this.data_selection;
            
            x=this.Data.x(ind);
            y=this.Data.y(ind);
            
            %Setting upper and lower limits
            [amp_max,ind_max]=max(y);
            [amp_min,ind_min]=min(y);

            this.lim_upper=[Inf,Inf,Inf];
            this.lim_lower=-this.lim_upper;

            %Fix to avoid unphysical offsets on data where all y values 
            %exceed 0.
            if all(y>0)
                this.lim_lower(3)=0;
            end

            if abs(amp_max)>abs(amp_min)
                this.lim_upper(1)=Inf;
                this.lim_lower(1)=0;
            else
                this.lim_upper(1)=0;
                this.lim_lower(1)=-Inf;
            end

            if (ind_max>ind_min && abs(amp_max)>abs(amp_min))...
                    || (ind_max<ind_min && abs(amp_max)<abs(amp_min))
                this.lim_upper(2)=Inf;
                this.lim_lower(2)=0;
            else
                this.lim_upper(2)=0;
                this.lim_lower(2)=-Inf;
            end

            %Method for estimating initial parameters taken from
            %http://www.matrixlab-examples.com/exponential-regression.html. 
            %Some modifications required to account for negative y values
            % y=y-amp_min;

            y=y-amp_min+eps;
            n=length(x);
            y2=log(y);
            j=sum(x);
            k=sum(y2);
            l=sum(x.^2);
            r2=sum(x .* y2);
            p_in(2)=(n * r2 - k * j)/(n * l - j^2);
            p_in(1)=exp((k-p_in(2)*j)/n);

            if abs(amp_max)>abs(amp_min)
                p_in(3)=amp_min;
            else
                p_in(3)=amp_max;
            end
            
            this.param_vals = p_in;
        end
    end
    
    methods (Access = private)
        function sc_vals = scaleFitParams(~, vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            sc_vals(2)=vals(2)*std_x;
            sc_vals(1)=vals(1)*exp(sc_vals(2)*mean_x/std_x)/std_y;
            sc_vals(3)=(vals(3)-mean_y)/std_y;
        end
        
        function vals = unscaleFitParams(~, sc_vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            vals(1)=exp(-sc_vals(2)*mean_x/std_x)*sc_vals(1)*std_y;
            
            %Edge case for limits
            if isnan(vals(1))
                vals(1)=0;
            end
            
            vals(2)=sc_vals(2)/std_x;
            vals(3)=std_y*sc_vals(3)+mean_y;
        end
    end
end