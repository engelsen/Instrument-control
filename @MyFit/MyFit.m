classdef MyFit < handle
    properties
        Gui
        Data;
        Fit;
        Parser;
        fit_name='linear'
        init_params=[];
        scale_init=[];
        FitStruct;
        Fitdata;
        coeffs;
        enable_gui=1;
        enable_plot;
        plot_handle;
    end
    
    properties (Dependent=true)
        fit_function;
        fit_tex;
        fit_params;
        fit_param_names;
        valid_fit_names;
        n_params;
        scaled_params;
        init_param_fun;
    end
    
    methods
        function this=MyFit(varargin)
            createFitStruct(this);
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this);
            if ismember('Data',this.Parser.UsingDefaults) &&...
                    ~ismember('x',this.Parser.UsingDefaults) &&...
                    ~ismember('y',this.Parser.UsingDefaults)
                
                this.Data.x=this.Parser.Results.x;
                this.Data.y=this.Parser.Results.y;
            end
            
            genInitParams(this);
            this.scale_init=ones(1,this.n_params);
            
            if this.enable_gui
                createGui(this);
            end
            
            
        end
        
        %Creates the GUI of MyFit
        createGui(this);
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','linear',@ischar)
            addParameter(p,'Data',MyTrace());
            addParameter(p,'Fit',MyTrace());
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'enable_gui',1);
            addParameter(p,'enable_plot',0);
            addParameter(p,'plot_handle',[]);
            this.Parser=p;
        end
        
        %Sets the class variables to the inputs from the inputParser.
        function parseInputs(this)
            for i=1:length(this.Parser.Parameters)
                %Takes the value from the inputParser to the appropriate
                %property.
                if isprop(this,this.Parser.Parameters{i})
                    this.(this.Parser.Parameters{i})=...
                        this.Parser.Results.(this.Parser.Parameters{i});
                end
            end
        end
        
        
        function fitTrace(this)
            this.Fit.x=linspace(min(this.Data.x),max(this.Data.x),1e3);
            switch this.fit_name
                case 'linear'
                    this.coeffs=polyfit(this.Data.x,this.Data.y,1);
                case 'quadratic'
                    this.coeffs=polyfit(this.Data.x,this.Data.y,2);
                case 'exponential'
                    this.Fitdata=fitExponential(this.Data.x,...
                        this.Data.y,this.scaled_params);
                    this.coeffs=coeffvalues(this.Fitdata);
                    this.Fit.y=this.Fitdata(this.Fit.x);
                otherwise
                    ft=fittype(this.fit_function);
                    this.Fitdata=fit(this.Data.x,this.Data.y,...
                        ft);
                    this.Fit.y=this.Fitdata(this.Fit.x)';
                    this.coeffs=coeffvalues(this.Fitdata);
            end
            
            this.init_params=this.coeffs;
            this.scale_init=ones(1,this.n_params);
            updateGui(this);
        end
        
        function createFitStruct(this)
            %Adds fits
            addFit(this,'linear','a*x_b','$$ax+b$$',{'a','b'},...
                {'Gradient','Offset'})
            addFit(this,'quadratic','a*x^2+b*x+c','$$ax^2+bx+c$$',...
                {'a','b','c'},{'Quadratic coeff.','Linear coeff.','Offset'});
            addFit(this,'gaussian','a*exp(-((x-c)/b)^2/2)+d',...
                '$$ae^{-\frac{(x-c)^2}{2b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'lorentzian','a/(pi)*(b/((x-c)^2+b^2))',...
                '$$\frac{a}{1+\frac{(x-c)^2}{b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'exponential','a*exp(b*x)+c',...
                '$$ae^{bx}+c$$',{'a','b','c'},...
                {'Amplitude','Rate','Offset'});
        end
        
        function updateGui(this)
            %Converts the scale variable to the value between 0 and 100
            %necessary for the slider
            slider_vals=25*log10(this.scale_init)+50;
            for i=1:this.n_params
                set(this.Gui.(sprintf('edit_%s',this.fit_params{i})),...
                    'String',sprintf('%3.3e',this.scaled_params(i)));
                set(this.Gui.(sprintf('slider_%s',this.fit_params{i})),...
                    'Value',slider_vals(i));
            end
        end
        
        %Adds a fit to the list of fits
        function addFit(this,fit_name,fit_function,fit_tex,fit_params,...
                fit_param_names)
            this.FitStruct.(fit_name).fit_function=fit_function;
            this.FitStruct.(fit_name).fit_tex=fit_tex;
            this.FitStruct.(fit_name).fit_params=fit_params;
            this.FitStruct.(fit_name).fit_param_names=fit_param_names;
            %Generates the anonymous fit function from the above
            args=['@(x,', strjoin(fit_params,','),')'];
            anon_fit_fun=str2func(vectorize([args,fit_function]));
            this.FitStruct.(fit_name).anon_fit_fun=anon_fit_fun;         
        end
        
        function genInitParams(this)
            switch this.fit_name
                case 'exponential'
                    this.init_params=initParamExponential(this.Data.x,...
                        this.Data.y);
                otherwise
                    this.init_params=ones(1,this.n_params);
            end
        end
        function slider_Callback(this, param_ind, hObject, ~)
            %Gets the value from the slider
            scale=get(hObject,'Value');
            %Updates the scale with a new value
            this.scale_init(param_ind)=10^((scale-50)/25);
            %Updates the edit box with the new value from the slider
            set(this.Gui.(sprintf('edit_%s',this.fit_params{param_ind})),...
                'String',sprintf('%3.3e',this.scaled_params(param_ind)));
            if this.enable_plot; plotInitFun(this); end

        end
        
        function edit_Callback(this, hObject, ~)
            init_param=str2double(get(hObject,'String'));
            tag=get(hObject,'Tag');
            %Finds the index where the fit_param name begins (convention is
            %after the underscore)
            fit_param=tag((strfind(tag,'_')+1):end);
            param_ind=strcmp(fit_param,this.fit_params);
            %Updates the slider to be such that the scaling is 1
            set(this.Gui.(sprintf('slider_%s',fit_param)),...
                'Value',50);
            %Updates the correct initial parameter
            this.init_params(param_ind)=init_param;
            if this.enable_plot; plotInitFun(this); end
        end
        
        function plotInitFun(this)
            %Substantially faster than any alternative - generating 
            %anonymous functions is very cpu intensive. Further
            %improvements could be made by using set(Xdata,Ydata)
            x_vec=linspace(min(this.Data.x),max(this.Data.x),1000);
            input_cell=num2cell(this.scaled_params);
            y_vec=feval(this.FitStruct.(this.fit_name).anon_fit_fun,x_vec,...
                input_cell{:});
            plot(this.plot_handle,x_vec,y_vec);
        end
        
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
            this.fit_name=lower(fit_name);
        end
        
        function valid_fit_names=get.valid_fit_names(this)
            valid_fit_names=fieldnames(this.FitStruct);
        end
        
        function fit_function=get.fit_function(this)
            assert(ismember(this.fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',this.fit_name);
            fit_function=this.FitStruct.(this.fit_name).fit_function;
        end
        
        function fit_tex=get.fit_tex(this)
            assert(ismember(this.fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',this.fit_name);
            fit_tex=this.FitStruct.(this.fit_name).fit_tex;
        end
        
        function fit_params=get.fit_params(this)
            assert(ismember(this.fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',this.fit_name);
            fit_params=this.FitStruct.(this.fit_name).fit_params;
        end
        
        function fit_param_names=get.fit_param_names(this)
            assert(ismember(this.fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',this.fit_name);
            fit_param_names=this.FitStruct.(this.fit_name).fit_param_names;
        end
        
        function scaled_params=get.scaled_params(this)
            scaled_params=this.scale_init.*this.init_params;
        end
        
        function n_params=get.n_params(this)
            n_params=length(this.fit_params);
        end

    end
end