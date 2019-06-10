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
        %Calculates the initial parameters using an external function.
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            [init_params,lim_lower,lim_upper]=...
                initParamDblLorentzian(this.Data.x,this.Data.y);
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