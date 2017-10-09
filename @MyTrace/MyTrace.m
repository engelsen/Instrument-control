classdef MyTrace < handle
    properties
        x=[];
        y=[];
        name='placeholder';
        Color='b';
        Marker='.';
        LineStyle='-'
        MarkerSize=6;
        Parser;
        name_x='x';
        name_y='y';
        unit_x='';
        unit_y='';
    end
    
    properties (Dependent=true)
        label_x;
        label_y;
    end
    
    methods
        function this=MyTrace(name, x, y, varargin)
            createParser(this);
            parse(this.Parser,name,x,y,varargin{:});
            parseInputs(this,true);
        end
        
        function createParser(this)
            p=inputParser;
            addRequired(p,'name');
            addRequired(p,'x');
            addRequired(p,'y');
            addParameter(p,'Color','b');
            addParameter(p,'Marker','none');
            addParameter(p,'LineStyle','-');
            addParameter(p,'MarkerSize',6);
            addParameter(p,'unit_x','x');
            addParameter(p,'unit_y','y');
            addParameter(p,'name_x','x');
            addParameter(p,'name_y','y');
            this.Parser=p;
        end
        
        function parseInputs(this, default_flag)
            for i=1:length(this.Parser.Parameters)
                %Sets the value if there was an input or if the default
                %flag is on. The default flag is used to reset the class to
                %its default values.
                if default_flag || ~sum(ismember(this.Parser.Parameters{i},...
                        this.Parser.UsingDefaults))
                    this.(this.Parser.Parameters{i})=...
                        this.Parser.Results.(this.Parser.Parameters{i});
                end
            end
        end
        
        function plotTrace(this,plot_axes,varargin)
            assert(exist('plot_axes','var') && ...
                isa(plot_axes,'matlab.graphics.axis.Axes'),...
                'Please input axes to plot in.') 
            assert(isequal(size(this.x), size(this.y)) || ...
                (isvector(this.x) && isvector(this.y) && ...
                numel(this.x) == numel(this.y)),...
                'The length of x and y must be identical to make a plot')
            createParser(this);
            parse(this.Parser,this.name,this.x,this.y,varargin{:})
            parseInputs(this,false);
            plot(plot_axes,this.x,this.y,'Color',this.Color,'LineStyle',...
                this.LineStyle,'Marker',this.Marker,...
                'MarkerSize',this.MarkerSize)
            xlabel(plot_axes,this.label_x,'Interpreter','LaTeX');
            ylabel(plot_axes,this.label_y,'Interpreter','LaTeX');
            set(plot_axes,'TickLabelInterpreter','LaTeX');
        end
        
        function set.Color(this, Color)
            assert(iscolor(Color),...
                '%s is not a valid MATLAB default color or RGB triplet',Color);
            this.Color=Color;
        end
        
        function set.Marker(this, Marker)
            assert(ismarker(Marker),...
                '%s is not a valid MATLAB MarkerStyle',Marker);
            this.Marker=Marker;
        end
        
        function set.x(this, x)
            assert(isvector(x) && isnumeric(x),...
                'Data must be a vector of doubles');
            this.x=x;
        end
        
        function set.y(this, y)
            assert(isvector(y) && isnumeric(y),...
                'Data must be a vector of doubles');
            this.y=y;
        end
        
        function set.LineStyle(this, LineStyle)
            assert(isline(LineStyle),...
                '%s is not a valid MATLAB LineStyle',LineStyle);
            this.LineStyle=LineStyle;
        end
        
        function set.MarkerSize(this, MarkerSize)
            assert(isnumeric(MarkerSize) && MarkerSize>0,...
                'MarkerSize must be a numeric value greater than zero');
            this.MarkerSize=MarkerSize;
        end
        
        function set.name(this, name)
            assert(ischar(name),'Name must be a string, not a %s',...
                class(name));
            this.name=name;
        end
        
        function set.unit_x(this, unit_x)
            assert(ischar(unit_x),'Unit must be a string, not a %s',...
                class(unit_x));
            this.unit_x=unit_x;
        end
        
        function set.unit_y(this, unit_y)
            assert(ischar(unit_y),'Unit must be a string, not a %s',...
                class(unit_y));
            this.unit_y=unit_y;
        end
        
        function set.name_x(this, name_x)
            assert(ischar(name_x),'Name must be a string, not a %s',...
                class(name_x));
            this.name_x=name_x;
        end
        
        function set.name_y(this, name_y)
            assert(ischar(name_y),'Name must be a string, not a %s',...
                class(name_y));
            this.name_y=name_y;
        end
        
        function label_x=get.label_x(this)
            label_x=sprintf('%s (%s)', this.name_x, this.unit_x);
        end
        
        function label_y=get.label_y(this)
            label_y=sprintf('%s (%s)', this.name_y, this.unit_y);
        end
        
    end
end

function bool=validateVector(vector)
assert(isvector(vector) && isnumeric(vector),...
    'Data must be a vector of doubles');
bool=true;
end

function bool=validateColor(color)
assert(iscolor(color),...
    '%s is not a valid MATLAB default color or RGB triplet',color);
bool=true;
end
function bool=validateMarker(marker)
assert(ismarker(marker),...
    '%s is not a valid MATLAB MarkerStyle',marker);
bool=true;
end

function validateLine(linestyle)
assert(isline(linestyle),...
    '%s is not a valid MATLAB LineStyle',linestyle);
end
function bool=validateSize(markersize)
assert(isnumeric(markersize) && markersize>0,...
    'MarkerSize must be a numeric value greater than zero');
bool=true;
end