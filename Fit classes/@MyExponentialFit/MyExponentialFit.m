classdef MyExponentialFit < MyFit
    properties (Access=public)
        %Logical value that determines whether the data should be scaled or
        %not
        scale_data;
        
    end
    
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyExponentialFit(varargin)
            this@MyFit(...
                'fit_name','Exponential',...
                'fit_function','a*exp(b*x)+c',...
                'fit_tex','$$ae^{bx}+c$$',...
                'fit_params',  {'a','b','c'},...
                'fit_param_names',{'Amplitude','Rate','Offset'},...
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
                    'StartPoint',convRealToScaledCoeffs(this,this.init_params),...
                    'MaxFunEvals',2000,...
                    'MaxIter',2000,...
                    'TolFun',1e-6,...
                    'TolX',1e-6);
                %Fits with the below properties. Chosen for maximum accuracy.
                [this.FitResult,this.Gof,this.FitInfo]=...
                    fit(this.Data.scaled_x,this.Data.scaled_y,ft,opts);
                %Puts the coeffs into the class variable.
                this.coeffs=convScaledToRealCoeffs(this,...
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
                    initParamExponential(this.Data.scaled_x,this.Data.scaled_y);
                %Convertion back to real values for display.
                init_params=convScaledToRealCoeffs(this,init_params);
                lim_lower=convScaledToRealCoeffs(this,lim_lower);
                lim_upper=convScaledToRealCoeffs(this,lim_upper);
            else
                [init_params,lim_lower,lim_upper]=...
                    initParamExponential(this.Data.x,this.Data.y);
            end
        end
        
        %Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            this.tau=abs(1/this.coeffs(2)); 
            this.lw=abs(this.coeffs(2)/pi); 
            this.Q=pi*this.freq*this.tau; 
            this.Qf=this.Q*this.freq; 
        end
        
        function createUserGuiStruct(this)
            this.UserGui.Tabs.Q.tab_title='Q';
            this.UserGui.Tabs.Q.Children={};
            addUserField(this,'Q','tau','\tau (s)',1,...
                'enable_flag','off')
            addUserField(this,'Q','lw','Linewidth (Hz)',1,...
                'enable_flag','off')
            addUserField(this,'Q','Q',...
                'Qualify Factor (x10^6)',1e6,...
                'enable_flag','off','conv_factor',1e6)
            addUserField(this,'Q','freq','Frequency (MHz)',1e6,...
                'conv_factor',1e6, 'enable_flag','on',...
                'Callback',@(~,~) calcUserParams(this));
            addUserField(this,'Q','Qf','Q\times f (10^{14} Hz)',1e14,...
                'conv_factor',1e14,'enable_flag','off');
            addUserField(this,'Q','tag','Tag (number)',1,...
                'enable_flag','on')
        end
        
    end
    
    methods (Access=private)
        %Converts scaled coefficients to real coefficients
        function r_c=convScaledToRealCoeffs(this,s_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            r_c(1)=exp(-s_c(2)*mean_x/std_x)*s_c(1)*std_y;
            %Edge case for limits
            if isnan(r_c(1)); r_c(1)=0; end
            
            r_c(2)=s_c(2)/std_x;
            r_c(3)=std_y*s_c(3)+mean_y;
        end
        
        function s_c=convRealToScaledCoeffs(this,r_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            s_c(2)=r_c(2)*std_x;
            s_c(1)=r_c(1)*exp(s_c(2)*mean_x/std_x)/std_y;
            s_c(3)=(r_c(3)-mean_y)/std_y;
        end
    end
    
end