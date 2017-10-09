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
            parseInputs(this);
        end
        
        function createParser(this)
            p=inputParser;
            addRequired(p,'name',@ischar);
            addRequired(p,'x',@validateVector);
            addRequired(p,'y',@validateVector);
            addParameter(p,'Color','b',@validateColor);
            addParameter(p,'Marker','.',@validateMarker);
            addParameter(p,'LineStyle','-',@validateLine);
            addParameter(p,'MarkerSize',6,@validateSize);
            addParameter(p,'unit_x','x',@ischar);
            addParameter(p,'unit_y','y',@ischar);
            this.Parser=p;
        end
        
        function parseInputs(this)
            for i=1:length(this.Parser.Parameters)
                this.(this.Parser.Parameters{i})=...
                    this.Parser.Results.(this.Parser.Parameters{i});
            end
        end
        
        function plotTrace(this,plot_axes,varargin)
            if ~exist('plot_axes','var') || ...
                    ~isa(plot_axes,'matlab.graphics.axis.Axes')
                error('Please input axes to plot in.')
            end
            createParser(this);
            parse(this.Parser,this.name,this.x,this.y,varargin{:})
            parseInputs(this);
            plot(plot_axes,this.x,this.y,'Color',this.Color,'LineStyle',...
                this.LineStyle,'Marker',this.Marker,...
                'MarkerSize',this.MarkerSize)
            xlabel(plot_axes,this.label_x,'Interpreter','LaTeX');
            ylabel(plot_axes,this.label_y,'Interpreter','LaTeX');
            set(plot_axes,'TickLabelInterpreter','LaTeX');
            
        end
            
        function set.Color(this, Color)
            if validateColor(Color); this.Color=Color; end
        end
        
        function set.Marker(this, Marker)
            if validateMarker(Marker); this.Marker=Marker; end
        end
        
        function set.x(this, x)
            if validateVector(x); this.x=x; end
        end
        
        function set.y(this, y)
            if validateVector(y); this.y=y; end
        end
        
        function set.LineStyle(this, LineStyle)
            if validateLine(LineStyle); this.LineStyle=LineStyle; end
        end
        
        function set.MarkerSize(this, MarkerSize)
            if validateSize(MarkerSize); this.MarkerSize=MarkerSize; end
        end
        
        function set.name(this, name)
            assert(ischar(name),'Name must be a string, not a %s',...
                class(name));
            this.name=name;
        end
        
        function set.unit_x(this, unit_x)
            assert(ischar(unit_x),'Name must be a string, not a %s',...
                class(unit_x));
            this.unit_x=unit_x;
        end
        
        function set.unit_y(this, unit_y)
            assert(ischar(unit_y),'Name must be a string, not a %s',...
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

function bool=validateLine(linestyle)
assert(isline(linestyle),...
    '%s is not a valid MATLAB LineStyle',linestyle);
bool=true;
end
function bool=validateSize(markersize)
assert(isnumeric(markersize) && markersize>0,...
    'MarkerSize must be a numeric value greater than zero');
bool=true;
end