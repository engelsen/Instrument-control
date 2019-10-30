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
        function [p_in,lim_lower,lim_upper]=calcInitParams(this)
            x = this.Data.x;
            y = this.Data.y;
            
            %Assumes form a/pi*b/2/((x-c)^2+(b/2)^2)+d

            lim_upper=[Inf,Inf,Inf,Inf,Inf];
            lim_lower=[-Inf,0,-Inf,-Inf,-Inf];

            %Finds peaks on the positive signal (max 1 peak)
            try
                [~,locs(1),widths(1),proms(1)]=findpeaks(y,x,...
                    'MinPeakDistance',range(x)/2,'SortStr','descend',...
                    'NPeaks',1);
            catch
                proms(1)=0;
            end

            %Finds peaks on the negative signal (max 1 peak)
            try
                [~,locs(2),widths(2),proms(2)]=findpeaks(-y,x,...
                    'MinPeakDistance',range(x)/2,'SortStr','descend',...
                    'NPeaks',1);
            catch
                proms(2)=0;
            end

            if proms(1)==0 && proms(2)==0
                warning('No peaks were found in the data, giving default initial parameters to fit function')
                p_in=[1,1,1,1,1];
                lim_lower=-[Inf,0,Inf,Inf];
                lim_upper=[Inf,Inf,Inf,Inf];
                return
            end

            %If the prominence of the peak in the positive signal is greater, we adapt
            %our limits and parameters accordingly, if negative signal has a greater
            %prominence, we use this for fitting.
            if proms(1)>proms(2)
                ind=1;
                p_in(5)=min(y);
            else
                ind=2;
                p_in(5)=max(y);
                proms(2)=-proms(2);
            end

            p_in(2)=widths(ind);
            %Calculates the amplitude, as when x=c, the amplitude is 2a/(pi*b)
            p_in(1)=proms(ind)*pi*p_in(2)/2;
            p_in(3)=locs(ind);

            p_in(4)=(y(end)-y(1))/(x(end)-x(1));

            lim_lower(2)=0.01*p_in(2);
            lim_upper(2)=100*p_in(2);
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