% Class for NewData events that are generated by MyDataSource and its
% subclasses, including MyInstrument
%
% Note: traces must be passed by value in order to make sure that they 
% are not modified after being sent.

classdef MyNewDataEvent < event.EventData
    
    properties (Access = public)

        % Cell array of trace objects 
        traces = {}
        
        % A character string or cellstring containing optional tags 
        % describing the traces
        trace_tags = {}
    end
    
    methods (Access = public) 
        
        % Use parser to process properties supplied as name-value pairs via
        % varargin
        function this = MyNewDataEvent(varargin)
            p = inputParser();
            addParameter(p, 'traces', {});
            addParameter(p, 'trace_tags', {});
            parse(p, varargin{:})
            
            this.traces = p.Results.traces;
            this.trace_tags = p.Results.trace_tags;
        end
    end

    methods
        function set.traces(this, val)
            assert(isa(val, 'MyTrace') || (iscell(val) && ...
                all(cellfun(@(x)isa(x, 'MyTrace'), val))), ...
                ['''traces'' must be a derivative of MyTrace or a ' ...
                'cell array of such.'])
            
            if isa(val, 'MyTrace')
                
                % A single trace can be given directly, it is 
                % wrapped in a cell for uniformity
                val = {val};
            end
            
            this.traces = val;
        end
        
        function set.trace_tags(this, val)
            assert(ischar(val) || iscellstr(val), ['The value ' ...
                'assigned to ''trace_tags'' must be a character string '...
                'or a cell of character strings.']) %#ok<ISCLSTR>
            
            if ischar(val)
                
                % A single tag can be given as character string, it is 
                % converted to cell array for uniformity
                val = {val};
            end
            
            this.trace_tags = val;
        end
    end
end