classdef MyFit < handle
    properties (Access=public)
        Data;
        init_params=[];
        scale_init=[];
        lim_lower;
        lim_upper;
        enable_plot;
        plot_handle;
        save_name;
        save_dir;
    end
    
    properties (GetAccess=public, SetAccess=private)
        Fit;
        Gui;
        Fitdata;
        coeffs;
        fit_name='Linear'
    end
    
    properties (Access=private)
        Parser;
        FitStruct;
        enable_gui=1;
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
    end
    
    %%Public methods
    methods (Access=public)
        %Constructor function
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
            
            %If the data is appropriate, generates initial
            %parameters
            if validateData(this)
                genInitParams(this);
            else
                this.init_params=ones(1,this.n_params);
            end
            
            %Sets the scale_init to 1, this is used for the GUI.
            this.scale_init=ones(1,this.n_params);
            
            if this.enable_gui
                createGui(this);
            end
        end
        
        %Deletion function of object
        function delete(this)
            if this.enable_gui
                %Avoids loops
                set(this.Gui.Window,'CloseRequestFcn','');
                %Deletes the figure
                delete(this.Gui.Window);
                %Removes the figure handle to prevent memory leaks
                this.Gui=[];
            end
            if ~isempty(this.hline_init); delete(this.hline_init); end
            if ~isempty(this.Fit.hlines); delete(this.Fit.hlines{:}); end
        end
        %Close figure callback simply calls delete function for class
        function closeFigure(this,~,~)
            delete(this);
        end
        
        %Fits the trace using currently set parameters, depending on the
        %model.
        function fitTrace(this)
            this.Fit.x=this.x_vec;
            switch this.fit_name
                case 'Linear'
                    %Fits polynomial of order 1
                    this.coeffs=polyfit(this.Data.x,this.Data.y,1);
                    this.Fit.y=polyval(this.coeffs,this.Fit.x);
                case 'Quadratic'
                    %Fits polynomial of order 2
                    this.coeffs=polyfit(this.Data.x,this.Data.y,2);
                    this.Fit.y=polyval(this.coeffs,this.Fit.x);
                case {'Exponential','Gaussian','Lorentzian'}
                    doFit(this);
            end
            %Sets the new initial parameters to be the fitted parameters
            this.init_params=this.coeffs;
            %Resets the scale variables for the GUI
            this.scale_init=ones(1,this.n_params);
            %Updates the gui if it is enabled
            if this.enable_gui; updateGui(this); end
            %Plots the fit if the flag is on
            if this.enable_plot; plotFit(this); end
            %Triggers new fit event
            triggerNewFit(this);
        end
        
        %% Callbacks
        %Save function callback
        function saveCallback(this,~,~)
            assert(~isempty(this.save_dir),'Save directory is not specified');
            assert(ischar(this.save_dir),...
                ['Save directory is not specified.',...
                ' Should be of type char but is %s.'], ...
                class(this.save_dir))
            try
                this.Fit.save('name',this.save_name,...
                    'save_dir',this.save_dir)
            catch
                error(['Attempted to save to directory %s',...
                    ' with file name %s, but failed'],this.save_dir,...
                    this.save_name);
            end
        end
        %Callback functions for sliders in GUI. Uses param_ind to find out
        %which slider the call is coming from, this was implemented to
        %speed up the callback.
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
        
        %Callback function for edit boxes in GUI
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
        
        %Callback function for analyze button in GUI. Checks if the data is
        %ready for fitting.
        function analyzeCallback(this, ~, ~)
            if validateData(this)
                fitTrace(this);
            else
                error(['The length of x is %d and the length of y is',...
                    ' %d. The lengths must be equal and greater than ',...
                    'the number of fit parameters to perform a fit'],...
                    length(this.Data.x), length(this.Data.y));
            end
        end
        
        function clearFitCallback(this,~,~)
            clearFit(this);
        end
        
        function initParamCallback(this,~,~)
            genInitParams(this);
            updateGui(this);
        end
        
        %Generates model-dependent initial parameters, lower and upper
        %boundaries.
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
        
        %Plots the trace contained in the Fit MyTrace object.
        function plotFit(this,varargin)
            this.Fit.plotTrace(this.plot_handle,varargin{:});
        end
                
        %Clears the plots
        function clearFit(this)
            cellfun(@(x) delete(x), this.Fit.hlines);
            this.Fit.hlines={};
        end
                
        %Function for plotting fit model with current initial parameters.
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
    end
    
    methods(Access=private)
        %Creates the GUI of MyFit, in separate file.
        createGui(this);
        
        %Creates parser for constructor
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
            addParameter(p,'save_dir',[]);
            addParameter(p,'save_name',[]);
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
        
        %Does the fit with the currently set parameters
        function doFit(this)
            %Fits with the below properties. Chosen for maximum accuracy.
            this.Fitdata=fit(this.Data.x,this.Data.y,this.fit_function,...
                'Lower',this.lim_lower,'Upper',this.lim_upper,...
                'StartPoint',this.init_params, ....
                'MaxFunEvals',2000,'MaxIter',2000,'TolFun',1e-9);
            %Puts the y values of the fit into the struct.
            this.Fit.y=this.Fitdata(this.Fit.x);
            %Puts the coeffs into the class variable.
            this.coeffs=coeffvalues(this.Fitdata);
        end
        
        %Triggers the NewFit event such that other objects can use this to
        %e.g. plot new fits
        function triggerNewFit(this)
            notify(this,'NewFit');
        end

        %Creates the struct used to get all things relevant to the fit
        %model
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
        
        %Updates the GUI if the edit or slider boxes are changed from
        %elsewhere.
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
        
        %Checks if the class is ready to perform a fit
        function bool=validateData(this)
            bool=~isempty(this.Data.x) && ~isempty(this.Data.y) && ...
                length(this.Data.x)==length(this.Data.y) && ...
                length(this.Data.x)>=this.n_params;
        end
    end
    
    %% Get and set functions
    methods
        %% Set functions
        
        %Set function for fit_name.
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
            %Capitalizes the first letter
            fit_name=[upper(fit_name(1)),lower(fit_name(2:end))];
            %Checks it is a valid fit name
            assert(ismember(fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',fit_name); %#ok<MCSUP>
            this.fit_name=fit_name;
        end
        
        %% Get functions for dependent variables
        
        %Generates the valid fit names
        function valid_fit_names=get.valid_fit_names(this)
            valid_fit_names=fieldnames(this.FitStruct);
        end
        
        %Grabs the correct fit function from FitStruct
        function fit_function=get.fit_function(this)
            fit_function=this.FitStruct.(this.fit_name).fit_function;
        end
        
        %Grabs the correct tex string from FitStruct
        function fit_tex=get.fit_tex(this)
            fit_tex=this.FitStruct.(this.fit_name).fit_tex;
        end
        
        %Grabs the correct fit parameters from FitStruct
        function fit_params=get.fit_params(this)
            fit_params=this.FitStruct.(this.fit_name).fit_params;
        end
        
        %Grabs the correct fit parameter names from FitStruct
        function fit_param_names=get.fit_param_names(this)
            fit_param_names=this.FitStruct.(this.fit_name).fit_param_names;
        end
        
        %Calculates the scaled initial parameters
        function scaled_params=get.scaled_params(this)
            scaled_params=this.scale_init.*this.init_params;
        end
        
        %Calculates the number of parameters in the fit function
        function n_params=get.n_params(this)
            n_params=length(this.fit_params);
        end
        
        %Generates a vector of x values for plotting
        function x_vec=get.x_vec(this)
            x_vec=linspace(min(this.Data.x),max(this.Data.x),1000);
        end
    end
end