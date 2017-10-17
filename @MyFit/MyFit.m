classdef MyFit < handle
    properties
        Gui
        DataTrace;
        FitTrace;
        Parser;
        fit_name='linear'
        init_params=[];
        FitStruct;
        CFitObj;
        coeffs;
        enable_gui=1;
    end
    
    properties (Dependent=true)
        fit_function;
        fit_tex;
        fit_params;
        fit_param_names;
        valid_fit_names;
    end

    methods
        function this=MyFit(varargin)
            createFitStruct(this);
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this);
            if ismember('DataTrace',this.Parser.UsingDefaults) &&...
                ~ismember('x',this.Parser.UsingDefaults) &&...
                ~ismember('y',this.Parser.UsingDefaults)
            
                this.DataTrace.x=this.Parser.Results.x;
                this.DataTrace.y=this.Parser.Results.y;
            end
            if this.enable_gui
                createGui(this);
            end
        end
        
        %Creates the GUI of MyFit
        createGui(this);
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','linear',@ischar)
            addParameter(p,'DataTrace',MyTrace());
            addParameter(p,'FitTrace',MyTrace());
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'enable_gui',1);
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
        
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
           this.fit_name=lower(fit_name); 
        end
        
        function fitTrace(this)
            switch this.fit_name
                case 'linear'
                    this.coeffs=polyfit(this.DataTrace.x,this.DataTrace.y,1);
                case 'quadratic'
                    this.coeffs=polyfit(this.DataTrace.x,this.DataTrace.y,2);
                case 'exponential'
                    this.CFitObj=fitExponential(this.DataTrace.x,...
                        this.DataTrace.y);
                otherwise
                    ft=fittype(this.fit_function);
                    this.CFitObj=fit(this.DataTrace.x,this.DataTrace.y,...
                        ft);
                    this.FitTrace.x=linspace(min(this.DataTrace.x),...
                        max(this.DataTrace.x),1e4);
                    this.FitTrace.y=this.CFitObj(this.FitTrace.x)';
            end
        end
        function createFitStruct(this)
            %Adds the linear fit
            addFit(this,'linear','a*x_b','$$ax+b$$',{'a','b'},...
                {'Gradient','Offset'})
            addFit(this,'quadratic','a*x^2+b*x+c','$$ax^2+bx+c$$',...
                {'a','b','c'},{'Quadratic coeff.','Linear coeff.','Offset'});
            addFit(this,'gaussian','a*exp(-((x-c)/b)^2/2)+d',...
                '$$ae^{-\frac{(x-c)^2}{2b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'lorentzian','a/(pi)*(b/((x-c)^2+b^2)',...
                '$$\frac{a}{1+\frac{(x-c)^2}{b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'exponential','a*exp(-b*x)+c',...
                '$$ae^{-bx}+c$$',{'a','b','c'},...
                {'Amplitude','Decay constant','Offset'});
        end
        
        function addFit(this,fit_name,fit_function,fit_tex,fit_params,...
                fit_param_names)
            this.FitStruct.(fit_name).fit_function=fit_function;
            this.FitStruct.(fit_name).fit_tex=fit_tex;
            this.FitStruct.(fit_name).fit_params=fit_params;
            this.FitStruct.(fit_name).fit_param_names=fit_param_names;
        end
        
        function slider_Callback(this, param_ind, hObject, ~)
            %Gets the value from the slider
            init_param=get(hObject,'Value');
            %Updates the edit box with the new value from the slider
            set(this.Gui.(sprintf('edit_%s',this.fit_params{param_ind})),...
                'String',init_param);
            %Updates the class with the new value
            this.init_params(param_ind)=init_param;
        end
        
        function edit_Callback(this, hObject, ~)
           init_param=str2double(get(hObject,'String'));
           tag=get(hObject,'Tag');
           %Finds the index where the fit_param name begins (convention is
           %after the underscore)
           fit_param_name=tag((strfind(tag,'_')+1):end);
           param_ind=strcmp(fit_param_name,this.fit_param_names);
           %Updates the slider with the new value from the edit box
           set(this.Gui.(sprintf('slider_%s',fit_param_name)),...
               'Value',init_param);
           %Updates the correct initial parameter
           this.init_params(param_ind)=init_param;
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
    end
end