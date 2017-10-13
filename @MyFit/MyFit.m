classdef MyFit < handle
    properties
        DataTrace;
        FitTrace;
        Parser;
        fit_name='linear'
        valid_fit_names={'linear','quadratic','gaussian','lorentzian'}
        CFitObj;
        coeffs;
    end
    
    properties (Dependent=true)
        fit_function;
    end

    methods
        function this=MyFit(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            this.Parser.Results
            parseInputs(this);
            if ismember('DataTrace',this.Parser.UsingDefaults) &&...
                ~ismember('x',this.Parser.UsingDefaults) &&...
                ~ismember('y',this.Parser.UsingDefaults)
            
                this.DataTrace.x=this.Parser.Results.x;
                this.DataTrace.y=this.Parser.Results.y;
            end
        end
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','linear',@ischar)
            addParameter(p,'DataTrace',MyTrace());
            addParameter(p,'FitTrace',MyTrace());
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            this.Parser=p;
            this.Parser
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
                otherwise
                    this.CFitObj=fitArbFun(this.fit_function,...
                        this.DataTrace.x,this.DataTrace.y);
                    this.FitTrace.x=linspace(min(this.DataTrace.x),...
                        max(this.DataTrace.x),1e4);
                    this.FitTrace.y=this.CFitObj(this.FitTrace.x)';
            end
        end

        function fit_function=get.fit_function(this)
            assert(ismember(this.fit_name,this.valid_fit_names),...
                '%s is not a supported fit name',this.fit_name);
           switch this.fit_name
               case 'linear'
                   fit_function='a*x+b';
               case 'quadratic'
                   fit_function='a*x^2+b*x+c';
               case 'gaussian'
                   fit_function='a*exp(-((x-c)/b)^2/2)+d';
               case 'lorentzian'
                   fit_function='a/(pi)*(b/((x-c)^2+b^2)';
           end
        end
        
    end
end