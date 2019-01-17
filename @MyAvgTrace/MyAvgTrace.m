% Adds averaging capabilities to MyTrace

classdef MyAvgTrace < MyTrace

    properties (GetAccess=public, SetAccess=protected)
        % Counter for the averaging function, can be reset by clearData
        avg_count=1
    end
    
    methods
        function addAverage(this, b)
            
            if isa(b,'MyTrace')
                checkArithmetic(this,b);
                this.y=(this.y*this.avg_count+b.y)/(this.avg_count+1);
            elseif isnumeric(b)
                assert(isvector(b) && length(b)==length(this.y), ...
                    ['Numeric array must be a vector of the same ', ...
                    'length as y data of MyTrace in order to perform ', ...
                    'averanging'])
                this.y=(this.y*this.avg_count+b)/(this.avg_count+1);
            else
                error(['Second argument must be a MyTrace object or ', ...
                    'a numerical vector of the same length as y data ', ...
                    'of MyTrace in order to perform averanging'])
            end
            
            this.avg_count=this.avg_count+1;
        end
        
        function clearData(this)
            this.x=[];
            this.y=[];
            this.avg_count=1;
        end
    end
end

