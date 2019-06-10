classdef MyGorodetsky2000Fit < MyFit
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyGorodetsky2000Fit(varargin)
            this@MyFit(...
                'fit_name','Gorodetsky2000',...
                'fit_function',['a*abs( (k0^2/4 - kex^2/4 + gamma^2/4 - (x-b).^2 + i*k0.*(x-b))',...
                './( (k0 + kex)^2/4 + gamma^2/4 - (x-b).^2 + i.*(x-b)*(k0 + kex) )).^2+c*(x-b)'],...
                'fit_tex',['$$a\left|\frac{\kappa_0^2/4-\kappa_{ex}^2/4+\gamma^2/4-(x-b)^2+i\kappa_0(x-b)/2}',...
                '{(\kappa_0+\kappa_{ex})^2/4+\gamma^2/4-(x-b)^2+i(x-b)(\kappa_0+\kappa_{ex})}\right|^2$$+c(x-b)'],...
                'fit_params',  { 'a','b','c','gamma','k0', 'kex'},...
                'fit_param_names',{'Background','Center','BG Slope','Mode splitting',...
                'Intrinsic','Extrinsic'},...
                varargin{:});
        end
    end
    
    methods (Access=protected)
        %Calculates the initial parameters using an external function.
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            [init_params,lim_lower,lim_upper]=...
                initParamGorodetsky2000(this.Data.x,this.Data.y);
        end
        
        function genSliderVecs(this)
            genSliderVecs@MyFit(this);
            
            if validateData(this)
                %We choose to have the slider go over the range of
                %the x-values of the plot for the center of the
                %Lorentzian.
                this.slider_vecs{2}=...
                    linspace(this.x_vec(1),this.x_vec(end),101);
                %Find the index closest to the init parameter
                [~,ind]=...
                    min(abs(this.init_params(2)-this.slider_vecs{2}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{2})),'Value',ind-1);
            end
        end 
    end 
end