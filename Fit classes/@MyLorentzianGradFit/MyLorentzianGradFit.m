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
        function calcInitParams(this)
            x = this.Data.x;
            y = this.Data.y;

            %Assumes form a/pi*b/2/((x-c)^2+(b/2)^2)+d*(x-c)+e

            this.lim_upper = [Inf, Inf, Inf, Inf, Inf];
            this.lim_lower = [-Inf, 0, -Inf, -Inf, -Inf];

            % Find peaks using temporary variables to safely handle the
            % case where findpeaks returns empty (no exception is raised).
            rng_x = max(x) - min(x);
            proms = [0, 0];
            locs  = [mean(x), mean(x)];
            widths = [rng_x/10, rng_x/10];

            [~, lp, wp, pp] = findpeaks(y, x, ...
                'MinPeakDistance', rng_x/2, 'SortStr', 'descend', 'NPeaks', 1);
            if ~isempty(pp)
                locs(1) = lp; widths(1) = wp; proms(1) = pp;
            end

            [~, lp, wp, pp] = findpeaks(-y, x, ...
                'MinPeakDistance', rng_x/2, 'SortStr', 'descend', 'NPeaks', 1);
            if ~isempty(pp)
                locs(2) = lp; widths(2) = wp; proms(2) = pp;
            end

            if proms(1)==0 && proms(2)==0
                warning(['No peaks were found in the data, giving ' ...
                    'default initial parameters to fit function'])
                this.param_vals = [1, 1, 1, 1, 1];
                this.lim_lower  = [-Inf, 0, -Inf, -Inf, -Inf];
                this.lim_upper  = [Inf, Inf, Inf, Inf, Inf];
                return
            end

            %If the prominence of the peak in the positive signal is greater, we adapt
            %our limits and parameters accordingly, if negative signal has a greater
            %prominence, we use this for fitting.
            p_in = zeros(1, 5);
            if proms(1) > proms(2)
                ind = 1;
                p_in(5) = min(y);
            else
                ind = 2;
                p_in(5) = max(y);
                proms(2) = -proms(2);
            end

            p_in(2) = widths(ind);
            %Calculates the amplitude, as when x=c, the amplitude is 2a/(pi*b)
            p_in(1) = proms(ind) * pi * p_in(2) / 2;
            p_in(3) = locs(ind);
            p_in(4) = (y(end) - y(1)) / (x(end) - x(1));

            this.param_vals    = p_in;
            this.lim_lower(2)  = 0.01 * p_in(2);
            this.lim_upper(2)  = 100  * p_in(2);
        end
        
        function genSliderVecs(this)
            genSliderVecs@MyFit(this);

            if validateData(this.Data)
                %We choose to have the slider go over the range of
                %the x-values of the data for the center of the Lorentzian.
                this.slider_vecs{3}=...
                    linspace(this.Data.x(1),this.Data.x(end),101);
                %Find the index closest to the current parameter value
                [~,ind]=...
                    min(abs(this.param_vals(3)-this.slider_vecs{3}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{3})),'Value',ind-1);
            end
        end
    end 
end