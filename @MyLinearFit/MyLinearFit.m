classdef MyLinearFit < MyFit
    properties (Access=public)
        %Logical value that determines whether the data should be scaled or
        %not
        scale_data;
    end
    
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyLinearFit(varargin)
            this@MyFit(...
                'fit_name','Linear',...
                'fit_function','a*x+b',...
                'fit_tex','$$ax+bx$$',...
                'fit_params',{'a','b'},...
                'fit_param_names',{'Gradient','Offset'},...
                varargin{:});
        end
        
    end
    
    methods (Access=protected)
        %Overload the doFit function to do polyFit instead of nonlinear
        %fitting. We here have the choice of whether to scale the data or
        %not.
        
        function doFit(this)
            if this.scale_data
                s_c=...
                    polyfit(this.Data.scaled_x,this.Data.scaled_y,1);
                this.coeffs=convScaledToRealCoeffs(this,s_c);
            else
                %Fits polynomial of order 1
                this.coeffs=polyfit(this.Data.x,this.Data.y,1);
            end
        end
    end
    
    methods (Access=private)
        %Converts scaled coefficients to real coefficients
        function r_c=convScaledToRealCoeffs(this,s_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            r_c(1)=std_y/std_x*s_c(1);
            r_c(2)=(s_c(2)-s_c(1)*mean_x/std_x)*std_y+mean_y;
        end
        
        function s_c=convRealToScaledCoeffs(this,r_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            s_c(1)=std_x/std_y*r_c(1);
            s_c(2)=(r_c(2)-mean_y)/std_y+s_c(1)*mean_x/std_x;
        end
    end
   
end