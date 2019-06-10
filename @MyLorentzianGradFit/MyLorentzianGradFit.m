classdef MyLorentzianGradFit < MyFit
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyLorentzianGradFit(varargin)
            this@MyFit(...
                'fit_name','LorentzianGrad',...
                'fit_function','1/pi*a*b/2/((x-c)^2+(b/2)^2)+d*(x-c)+e',...
                'fit_tex','$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d(x-c)+e$$',...
                'fit_params',  {'a','b','c','d','e'},...
                'fit_param_names',{'Amplitude','Width','Center','Gradient','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access=protected)
        %Calculates the initial parameters using an external function.
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            [init_params,lim_lower,lim_upper]=...
                initParamLorentzianGrad(this.Data.x,this.Data.y);
        end
        
        function genSliderVecs(this)
            genSliderVecs@MyFit(this);
            
            if validateData(this)
                %We choose to have the slider go over the range of
                %the x-values of the plot for the center of the
                %Lorentzian.
                this.slider_vecs{3}=...
                    linspace(this.x_vec(1),this.x_vec(end),101);
                %Find the index closest to the init parameter
                [~,ind]=...
                    min(abs(this.init_params(3)-this.slider_vecs{3}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{3})),'Value',ind-1);
            end
        end 
    end 
end