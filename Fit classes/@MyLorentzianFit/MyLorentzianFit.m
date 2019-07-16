classdef MyLorentzianFit < MyFit
    properties (Access=public)
        %Logical value that determines whether the data should be scaled or
        %not
        scale_data=true;
        %For calibration of optical frequencies using reference lines
        tot_spacing=1;
    end
    
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyLorentzianFit(varargin)
            this@MyFit(...
                'fit_name','Lorentzian',...
                'fit_function','1/pi*a*b/2/((x-c)^2+(b/2)^2)+d',...
                'fit_tex','$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d$$',...
                'fit_params',  {'a','b','c','d'},...
                'fit_param_names',{'Amplitude','Width','Center','Offset'},...
                varargin{:});
        end
    end
    
    methods (Access=protected)
        %Overload the doFit function to do scaled fits.
        %We here have the choice of whether to scale the data or not.
        function doFit(this)
            if this.scale_data
                ft=fittype(this.fit_function,'coefficients',...
                    this.fit_params);
                opts=fitoptions('Method','NonLinearLeastSquares',...
                    'Lower',convRealToScaledCoeffs(this,this.lim_lower),...
                    'Upper',convRealToScaledCoeffs(this,this.lim_upper),...
                    'StartPoint',convRealToScaledCoeffs(this,this.param_vals),...
                    'MaxFunEvals',2000,...
                    'MaxIter',2000,...
                    'TolFun',1e-6,...
                    'TolX',1e-6);
                %Fits with the below properties. Chosen for maximum accuracy.
                [this.FitResult,this.Gof,this.FitInfo]=...
                    fit(this.Data.scaled_x,this.Data.scaled_y,ft,opts);
                %Puts the coeffs into the class variable.
                this.param_vals=convScaledToRealCoeffs(this,...
                    coeffvalues(this.FitResult));
            else
                %Do the default fitting if we are not scaling.
                doFit@MyFit(this);
            end
            calcUserParams(this);
        end
        
        %Calculates the initial parameters using an external function.
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            if this.scale_data
                [init_params,lim_lower,lim_upper]=...
                    initParamLorentzian(this.Data.scaled_x,this.Data.scaled_y);
                %Convertion back to real values for display.
                init_params=convScaledToRealCoeffs(this,init_params);
                lim_lower=convScaledToRealCoeffs(this,lim_lower);
                lim_upper=convScaledToRealCoeffs(this,lim_upper);
            else
                [init_params,lim_lower,lim_upper]=...
                    initParamLorentzian(this.Data.x,this.Data.y);
            end
            
            this.param_vals = init_params;
            this.lim_lower = lim_lower;
            this.lim_upper = lim_upper;
        end
        
        %Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            this.mech_lw=this.param_vals(2); 
            this.mech_freq=this.param_vals(3); 
            this.Q=this.mech_freq/this.mech_lw; 
            this.opt_lw=convOptFreq(this,this.param_vals(2)); 
            this.Qf=this.mech_freq*this.Q;
        end
        
        function createUserGuiStruct(this)
            createUserGuiStruct@MyFit(this);
            
            %Parameters for the tab relating to mechanics
            this.UserGui.Tabs.Mech.tab_title='Mech.';
            this.UserGui.Tabs.Mech.Children={};
            addUserField(this,'Mech','mech_lw','Linewidth (Hz)',1,...
                'enable_flag','off')
            addUserField(this,'Mech','Q',...
                'Qualify Factor (x10^6)',1e6,...
                'enable_flag','off','conv_factor',1e6)
            addUserField(this,'Mech','mech_freq','Frequency (MHz)',1e6,...
                'conv_factor',1e6, 'enable_flag','off')
            addUserField(this,'Mech','Qf','Q\times f (10^{14} Hz)',1e14,...
                'conv_factor',1e14,'enable_flag','off');
            
            %Parameters for the tab relating to optics
            this.UserGui.Tabs.Opt.tab_title='Optical';
            this.UserGui.Tabs.Opt.Children={};
            addUserField(this,'Opt','line_spacing',...
                'Line Spacing (MHz)',1e6,'conv_factor',1e6,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','line_no','Number of lines',1,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','opt_lw','Linewidth (MHz)',1e6,...
                'enable_flag','off','conv_factor',1e6);
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
        
        %This function is used to convert the x-axis to frequency.
        function real_freq=convOptFreq(this,freq)
            real_freq=freq*this.line_spacing*this.line_no/this.tot_spacing;
        end
    end
    
    methods (Access=private)
        %Converts scaled coefficients to real coefficients
        function r_c=convScaledToRealCoeffs(this,s_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            r_c(1)=s_c(1)*std_y*std_x;
            r_c(2)=s_c(2)*std_x;
            r_c(3)=s_c(3)*std_x+mean_x;
            r_c(4)=s_c(4)*std_y+mean_y;
        end
        
        function s_c=convRealToScaledCoeffs(this,r_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            s_c(1)=r_c(1)/(std_y*std_x);
            s_c(2)=r_c(2)/std_x;
            s_c(3)=(r_c(3)-mean_x)/std_x;
            s_c(4)=(r_c(4)-mean_y)/std_y;
        end
    end
end