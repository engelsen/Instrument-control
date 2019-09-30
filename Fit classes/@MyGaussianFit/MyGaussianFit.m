classdef MyGaussianFit < MyFit
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyGaussianFit(varargin)
            this@MyFit(...
                'fit_name','Gaussian',...
                'fit_function','a*exp(-((x-c)/b)^2/2)+d',...
                'fit_tex', '$$ae^{-\frac{(x-c)^2}{2b^2}}+d$$',...
                'fit_params',{'a','b','c','d'},...
                'fit_param_names',{'Amplitude','Width','Center','Offset'},...
                varargin{:});
        end
    end
    methods (Access=protected)
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            x = this.Data.x;
            y = this.Data.y;
            
            %Assumes a*exp(-((x-c)/b)^2/2)+d - remember matlab orders the fit
            %parameters alphabetically

            bg=median(y);
            y=y-bg;

            [amp_max,ind_max]=max(y);
            [amp_min,ind_min]=min(y);

            lim_upper=[Inf,Inf,Inf,Inf];
            lim_lower=-lim_upper;

            if abs(amp_max)>abs(amp_min)
                amp=amp_max;
                center=x(ind_max);
                lim_upper(1)=Inf;
                lim_lower(1)=0;
            else
                amp=amp_min;
                center=x(ind_min);
                lim_upper(1)=0;
                lim_lower(1)=-Inf;
            end

            ind1=find(y>amp/2,1,'first');
            ind2=find(y>amp/2,1,'last');
            fwhm=x(ind2)-x(ind1);
            width=fwhm/2.35482;

            %Sets the lower limit on width to zero
            lim_lower(2)=0;

            %Sets the upper limit on width to 100 times the range of the data
            lim_upper(2)=100*range(x);

            %Sets upper and lower limit on the center
            lim_lower(3)=min(x)/2;
            lim_upper(3)=max(x)*2;

            init_params=[amp,width,center, bg];
        end
    end
end