classdef MyDoubleLorentzianFit < MyFit
    properties (Access=public)
        tot_spacing;
    end
    
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyDoubleLorentzianFit(varargin)
            this@MyFit(...
                'fit_name','DoubleLorentzian',...
                'fit_function','1/pi*b/2*a/((x-c)^2+(b/2)^2)+1/pi*e/2*d/((x-f)^2+(e/2)^2)+g',...
                'fit_tex','$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+\frac{d}{\pi}\frac{e/2}{(x-f)^2+(e/2)^2}+g$$',...
                'fit_params',  {'a','b','c','d','e','f','g'},...
                'fit_param_names',{'Amplitude 1','Width 1','Center 1','Amplitude 2',...
                'Width 2','Center 2','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access=protected)
        function [p_in,lim_lower,lim_upper]=calcInitParams(this)
            x = this.Data.x;
            y = this.Data.y;
            
            %Assumes form a/pi*b/2/((x-c)^2+(b/2)^2)+d/pi*e/2/((x-f)^2+(e/2)^2))+g

            lim_upper=[Inf,Inf,Inf,Inf,Inf,Inf,Inf];
            lim_lower=[-Inf,0,-Inf,-Inf,0,-Inf,-Inf];

            %Finds peaks on the positive signal (max 2 peaks)
            [~,locs{1},widths{1},proms{1}]=findpeaks(y,x,...
                'MinPeakDistance',0.01*range(x),'SortStr','descend','NPeaks',2);

            %Finds peaks on the negative signal (max 2 peaks)
            [~,locs{2},widths{2},proms{2}]=findpeaks(-y,x,...
                'MinPeakDistance',0.001*range(x),'SortStr','descend','NPeaks',2);

            %If the prominence of the peak in the positive signal is greater, we adapt
            %our limits and parameters accordingly, if negative signal has a greater
            %prominence, we use this for fitting.
            if isempty(proms{2}) || proms{1}(1)>proms{2}(1)
                ind=1;
                lim_lower(1)=0;
                lim_lower(4)=0;
                p_in(7)=min(y);
            else
                lim_upper(1)=0;
                lim_upper(4)=0;
                ind=2;
                p_in(7)=max(y);
                proms{2}=-proms{2};
            end

            p_in(2)=widths{ind}(1);
            %Calculates the amplitude, as when x=c, the amplitude is 2a/(pi*b)
            p_in(1)=proms{ind}(1)*pi*p_in(2)/2;
            p_in(3)=locs{ind}(1);
            if length(locs{ind})==2
                p_in(5)=widths{ind}(2);
                p_in(4)=proms{ind}(2)*pi*p_in(5)/2;
                p_in(6)=locs{ind}(2);
            else
                p_in(5)=widths{ind}(1);
                p_in(4)=proms{ind}(1)*pi*p_in(5)/2;
                p_in(6)=locs{ind}(1);
            end

            %If one of the lorentzians is found to be much smaller than the other, we
            %instead fit using only the greater lorentzian's parameters. This is an
            %adaption for very closely spaced lorentzians.
            if abs(p_in(1))>abs(10*p_in(4))
                p_in(1)=p_in(1)/2;
                p_in(5)=p_in(2);
                p_in(6)=p_in(3);
                p_in(4)=p_in(1);
            end

            lim_lower(2)=0.01*p_in(2);
            lim_upper(2)=100*p_in(2);

            lim_lower(5)=0.01*p_in(5);
            lim_upper(5)=100*p_in(5);
        end
        
        %Calculates user-defined parameters
        function calcUserParams(this)
            this.opt_lw1=convOptFreq(this,this.coeffs(2));
            this.opt_lw2=convOptFreq(this,this.coeffs(5));
            splitting=abs(this.coeffs(6)-this.coeffs(3));
            this.mode_split=convOptFreq(this,splitting);
        end
        
        %This function is used to convert the x-axis to frequency.
        function real_freq=convOptFreq(this,freq)
            real_freq=freq*this.line_spacing*this.line_no/this.tot_spacing;
        end
        
        function createUserGuiStruct(this)
            createUserGuiStruct@MyFit(this);
            this.UserGui.Tabs.Opt.tab_title='Optical';
            this.UserGui.Tabs.Opt.Children={};
            addUserField(this,'Opt','line_spacing',...
                'Line Spacing (MHz)',1e6,'conv_factor',1e6,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','line_no','Number of lines',10,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','opt_lw1','Linewidth 1 (MHz)',1e6,...
                'enable_flag','off','conv_factor',1e6);
            addUserField(this,'Opt','opt_lw2','Linewidth 2 (MHz)',1e6,...
                'enable_flag','off','conv_factor',1e6);
            addUserField(this,'Opt','mode_split',...
                'Modal splitting (MHz)',1e6,...
                'enable_flag','off','conv_factor',1e6);
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
                
                %Same for the other center
                this.slider_vecs{6}=...
                    linspace(this.x_vec(1),this.x_vec(end),101);
                %Find the index closest to the init parameter
                [~,ind]=...
                    min(abs(this.init_params(6)-this.slider_vecs{6}));
                %Set to ind-1 as the slider goes from 0 to 100
                set(this.Gui.(sprintf('Slider_%s',...
                    this.fit_params{6})),'Value',ind-1);
            end
        end 
    end 
end