classdef MyFit < handle
    properties
        Gui
        Data;
        Fit;
        Parser;
        FitStruct;
        Fitdata;
        fit_name='Linear'
        init_params=[];
        scale_init=[];
        lim_lower;
        lim_upper;
        coeffs;
        enable_gui=1;
        enable_plot;
        plot_handle;
        hline_init;
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
        x_vec;
    end
    
    events 
        NewFit;
        BeingDeleted;
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
            
            if ~isempty(this.Data.x) || ~isempty(this.Data.y) && ...
                    length(this.Data.y)==length(this.Data.x)
                genInitParams(this);
            else
                this.init_params=ones(1,this.n_params);
            end
            
            this.scale_init=ones(1,this.n_params);
            
            if this.enable_gui
                createGui(this);
            end         
        end
        
        %Creates the GUI of MyFit
        createGui(this);
        
        function delete(this)
            if this.enable_gui
                set(this.Gui.Window,'CloseRequestFcn','');
                %Deletes the figure
                delete(this.Gui.Window);
                %Removes the figure handle to prevent memory leaks
                this.Gui=[];
            end
            triggerBeingDeleted(this);
        end

        %Close figure callback simply calls delete function for class
        function closeFigure(this,~,~)
            delete(this);
        end
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','Linear',@ischar)
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
            this.Fit.x=this.x_vec;
            switch this.fit_name
                case 'Linear'
                    this.coeffs=polyfit(this.Data.x,this.Data.y,1);
                    this.Fit.y=polyval(this.coeffs,this.Fit.x);
                case 'Quadratic'
                    this.coeffs=polyfit(this.Data.x,this.Data.y,2);
                    this.Fit.y=polyval(this.coeffs,this.Fit.x);
                case {'Exponential','Gaussian','Lorentzian'}
                    doFit(this);
                otherwise
                    doFit(this);
            end
            
            this.init_params=this.coeffs;
            this.scale_init=ones(1,this.n_params);
            triggerNewFit(this);
            if this.enable_gui; updateGui(this); end
            if this.enable_plot; plotFit(this); end
        end
        
        function doFit(this)
            this.Fitdata=fit(this.Data.x,this.Data.y,this.fit_function,...
                'Lower',this.lim_lower,'Upper',this.lim_upper,...
                'StartPoint',this.init_params);
            this.Fit.y=this.Fitdata(this.Fit.x);
            this.coeffs=coeffvalues(this.Fitdata);
        end
        
        function triggerNewFit(this)
            notify(this,'NewFit');
        end
        
        function triggerBeingDeleted(this)
            notify(this,'BeingDeleted');
        end
        
        function plotFit(this)
            this.Fit.plotTrace(this.plot_handle);
        end
        
        function createFitStruct(this)
            %Adds fits
            addFit(this,'Linear','a*x+b','$$ax+b$$',{'a','b'},...
                {'Gradient','Offset'})
            addFit(this,'Quadratic','a*x^2+b*x+c','$$ax^2+bx+c$$',...
                {'a','b','c'},{'Quadratic coeff.','Linear coeff.','Offset'});
            addFit(this,'Gaussian','a*exp(-((x-c)/b)^2/2)+d',...
                '$$ae^{-\frac{(x-c)^2}{2b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'Lorentzian','a/((x-c)^2+(b/2)^2)+d',...
                '$$\frac{a}{(x-c)^2+(b/2)^2}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'Exponential','a*exp(b*x)+c',...
                '$$ae^{bx}+c$$',{'a','b','c'},...
                {'Amplitude','Rate','Offset'});
        end
        
        function updateGui(this)
            %Converts the scale variable to the value between 0 and 100
            %necessary for the slider
            slider_vals=25*log10(this.scale_init)+50;
            for i=1:this.n_params
                set(this.Gui.(sprintf('Edit_%s',this.fit_params{i})),...
                    'String',sprintf('%3.3e',this.scaled_params(i)));
                set(this.Gui.(sprintf('Slider_%s',this.fit_params{i})),...
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
                case 'Exponential'
                    [this.init_params,this.lim_lower,this.lim_upper]=...
                    initParamExponential(this.Data.x,this.Data.y);
                case 'Gaussian'
                    [this.init_params,this.lim_lower,this.lim_upper]=...
                    initParamGaussian(this.Data.x,this.Data.y);
                case 'Lorentzian'
                    [this.init_params,this.lim_lower,this.lim_upper]=...
                        initParamLorentzian(this.Data.x,this.Data.y);
                otherwise
                    this.init_params=ones(1,this.n_params);
            end
        end
        
        function sliderCallback(this, param_ind, hObject, ~)
            %Gets the value from the slider
            scale=get(hObject,'Value');
            %Updates the scale with a new value
            this.scale_init(param_ind)=10^((scale-50)/25);
            %Updates the edit box with the new value from the slider
            set(this.Gui.(sprintf('Edit_%s',this.fit_params{param_ind})),...
                'String',sprintf('%3.3e',this.scaled_params(param_ind)));
            if this.enable_plot; plotInitFun(this); end

        end
        
        function editCallback(this, hObject, ~)
            init_param=str2double(get(hObject,'String'));
            tag=get(hObject,'Tag');
            %Finds the index where the fit_param name begins (convention is
            %after the underscore)
            fit_param=tag((strfind(tag,'_')+1):end);
            param_ind=strcmp(fit_param,this.fit_params);
            %Updates the slider to be such that the scaling is 1
            set(this.Gui.(sprintf('Slider_%s',fit_param)),...
                'Value',50);
            %Updates the correct initial parameter
            this.init_params(param_ind)=init_param;
            if this.enable_plot; plotInitFun(this); end
        end
        
        function plotInitFun(this)
            %Substantially faster than any alternative - generating 
            %anonymous functions is very cpu intensive. 
            
            input_cell=num2cell(this.scaled_params);
            y_vec=feval(this.FitStruct.(this.fit_name).anon_fit_fun,...
                this.x_vec,input_cell{:});
            if isempty(this.hline_init)
                this.hline_init=plot(this.plot_handle,this.x_vec,y_vec);
            else
                set(this.hline_init,'XData',this.x_vec,'YData',y_vec);
            end
        end
        
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
            this.fit_name=[upper(fit_name(1)),lower(fit_name(2:end))];
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
        
        function x_vec=get.x_vec(this)
            x_vec=linspace(min(this.Data.x),max(this.Data.x),1000);
        end
    end
end