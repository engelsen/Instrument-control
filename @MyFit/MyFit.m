classdef MyFit < handle
    properties
        DataTrace;
        FitTrace;
        Parser;
        fit_name='linear'
        valid_fit_names={'linear','quadratic','gaussian','lorentzian'}
        CFitObj;
    end
    
    properties (Dependent=true)
        fit_function;
    end

    methods
        function this=MyFit(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this);
        end
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','linear',@ischar)
            addParameter(p,'DataTrace',MyTrace());
            addParameter(p,'FitTrace',MyTrace());
            this.Parser=p;
            this.Parser
        end
        
        %Sets the class variables to the inputs from the inputParser.
        function parseInputs(this)
            for i=1:length(this.Parser.Parameters)
            %Takes the value from the inputParser to the appropriate
            %property.
                this.(this.Parser.Parameters{i})=...
                    this.Parser.Results.(this.Parser.Parameters{i});
            end
        end
        
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
            assert(ismember(lower(fit_name),this.valid_fit_names),...
                '%s is not a supported fit name',fit_name);
           this.fit_name=fit_name; 
        end
        
        function fitData(this)
            this.CFitObj=fitArbFun(this.fit_function,...
                this.DataTrace.x,this.DataTrace.y);
            this.FitTrace.x=linspace(min(this.DataTrace.x),...
                max(this.DataTrace.x),1e4);
            this.FitTrace.y=this.CFitObj(this.FitTrace.x)';
        end

        function fit_function=get.fit_function(this)
           switch lower(this.fit_name)
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