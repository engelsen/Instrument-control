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
        function [p_in,lim_lower,lim_upper]=calcInitParams(this)
            x = this.Data.x;
            y = this.Data.y;
            
            %             { 'a','b','c', 'gamma','k0', 'kex'},...
            lim_upper=[Inf,Inf,Inf,Inf,Inf,Inf];
            lim_lower=[-Inf,-Inf,-Inf,0,0,0];


            %Finds peaks on the negative signal (max 2 peaks)
            rng_x = (max(x)-min(x));
            [~,locs,widths,~]=findpeaks(-y,x,...
                'MinPeakDistance',0.001*rng_x,'SortStr','descend','NPeaks',2);


            p_in(1)=max(y);

            %position
            p_in(2)=mean(locs);

            p_in(3)=(y(end)-y(1))/(x(end)-x(1));

            if length(locs)==2
                p_in(4)=abs(diff(locs))/2;
            else
                p_in(4)=0;
            end

            p_in(5)=mean(widths)/2;
            %Assume critical coupling
            p_in(6)=p_in(4);
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