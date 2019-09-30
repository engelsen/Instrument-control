classdef MyLorentzianFit < MyFitParamScaling
    
    methods (Access = public)
        function this = MyLorentzianFit(varargin)
            this@MyFitParamScaling( ...
                'fit_name',         'Lorentzian', ...
                'fit_function',     '1/pi*a*b/2/((x-c)^2+(b/2)^2)+d', ...
                'fit_tex',          '$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d$$', ...
                'fit_params',       {'a','b','c','d'}, ...
                'fit_param_names',  {'Amplitude','Width','Center','Offset'}, ...
                varargin{:});
        end
    end
    
    methods (Access = protected)
        
        function calcInitParams(this)
            ind = this.data_selection;
            
            x = this.Data.x(ind);
            y = this.Data.y(ind);

            this.lim_upper=[Inf,Inf,Inf,Inf];
            this.lim_lower=[-Inf,0,-Inf,-Inf];

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
                warning(['No peaks were found in the data, giving ' ...
                    'default initial parameters to fit function'])
                this.param_vals=[1,1,1,1];
                this.lim_lower=-[Inf,0,Inf,Inf];
                this.lim_upper=[Inf,Inf,Inf,Inf];
                return
            end

            %If the prominence of the peak in the positive signal is 
            %greater, we adapt our limits and parameters accordingly, 
            %if negative signal has a greater prominence, we use this 
            %for fitting.
            if proms(1)>proms(2)
                ind=1;
                p_in(4)=min(y);
            else
                ind=2;
                p_in(4)=max(y);
                proms(2)=-proms(2);
            end

            p_in(2)=widths(ind);
            
            %Calculates the amplitude, as when x=c, the amplitude 
            %is 2a/(pi*b)
            p_in(1)=proms(ind)*pi*p_in(2)/2;
            p_in(3)=locs(ind);

            this.param_vals = p_in;
            this.lim_lower(2)=0.01*p_in(2);
            this.lim_upper(2)=100*p_in(2);
        end
        
        function genSliderVecs(this)
            genSliderVecs@MyFit(this);
            
            try 
                
                %We choose to have the slider go over the range of
                %the x-values of the plot for the center of the
                %Lorentzian.
                this.slider_vecs{3}=...
                    linspace(this.Fit.x(1),this.Fit.x(end),101);
                %Find the index closest to the init parameter
                [~,ind]=...
                    min(abs(this.param_vals(3)-this.slider_vecs{3}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{3})),'Value',ind-1);
            catch 
            end
        end
    end
    
    methods (Access = protected)
        function sc_vals = scaleFitParams(~, vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            sc_vals(1)=vals(1)/(std_y*std_x);
            sc_vals(2)=vals(2)/std_x;
            sc_vals(3)=(vals(3)-mean_x)/std_x;
            sc_vals(4)=(vals(4)-mean_y)/std_y;
        end
        
        %Converts scaled coefficients to real coefficients
        function vals = unscaleFitParams(~, sc_vals, scaling_coeffs)
            [mean_x,std_x,mean_y,std_y]=scaling_coeffs{:};
            
            vals(1)=sc_vals(1)*std_y*std_x;
            vals(2)=sc_vals(2)*std_x;
            vals(3)=sc_vals(3)*std_x+mean_x;
            vals(4)=sc_vals(4)*std_y+mean_y;
        end
    end
end