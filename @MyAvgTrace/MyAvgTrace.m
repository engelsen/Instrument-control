% Adds averaging capabilities to MyTrace
%
% The averaging type is 'lin' (or 'linear')/ 'exp' (or 'exponential').
% Linear averaging is a simple mean 
% x=\sum_{n=0}^N x_n,
% exponential is an unlimited weighted sum 
% x=(1-exp(-1/n_avg))*\sum_{n=0}^\inf x_n exp(-n/n_avg).

classdef MyAvgTrace < MyTrace
    
    properties (Access=public)
        % Target number of averages, when it is reached or exceeded 
        % AveragingDone event is triggered
        n_avg=1 
        
        avg_type='lin'
    end
    
    properties (GetAccess=public, SetAccess=protected)
        % Counter for the averaging function, can be reset by clearData
        avg_count=0
    end
    
    methods (Access=public)
        
        % Adds data to the average accumulator. When the averaging counter
        % reaches n_avg (or exceeds it in the exponential case), completed
        % is set to 'true', otherwise 'false'.
        % In exponential regime the averaging proceeds indefinitely so that
        % avg_count can exceed n_avg.
        % In linear regime when the averaging counter exceeds n_avg, new
        % data is discarded.
        function completed = addAverage(this, b)
            assert(isa(b,'MyTrace') || (isvector(b) && isnumeric(b)), ...
                ['Second argument must be a MyTrace object or ', ...
                'a numeric vector'])
            
            if isa(b,'MyTrace')
                % The new data is supplied as MyTrace
                new_y=b.y;
            else
                % The new data is supplied directly as a numeric vector
                new_y=b(:);
            end
            
            if isempty(this)
                % Initialize new data and return
                this.y=new_y;
                this.avg_count=1;
                return
            end
            
            assert(length(new_y)==length(this.y), ...
                ['New vector of y values must be of the same', ...
                'length as the exisiting y data of MyTrace in ', ...
                'order to perform averanging'])
            
            switch this.avg_type
                case 'lin'
                    if this.avg_count<this.n_avg
                        % Increase the counter and update the data
                        this.avg_count=this.avg_count+1;
                        this.y = (this.y*(this.avg_count-1)+new_y)/...
                            this.avg_count;
                    end
                case 'exp'
                    % In the exponential case averaging proceeds
                    % indefinitely, so do not check if avg_count<n_avg
                    this.avg_count=this.avg_count+1;
                    this.y = new_y*(1-exp(-1/this.n_avg))+ ...
                        this.y*exp(-1/this.n_avg);
                otherwise
                    error('Averaging type %s is not supported', ...
                        this.avg_type)
            end
            
            completed=(this.avg_count>=this.n_avg);
        end
        
        % Provide restricted access to the trace averaging counter
        function resetCounter(this)
            this.avg_count=0;
        end
        
        % Overload clearData so that it reset the averaging counter in
        % addition to clearing the x and y values
        function clearData(this)
            this.x=[];
            this.y=[];
            resetCounter(this);
        end
    end
    
    %% Set and get methods
    
    methods
        
        % Ensure the supplied value for averaging mode is assigned in its
        % standard form - lowercase and abbreviated
        function set.avg_type(this, val)
            switch lower(val)
                case {'lin', 'linear'}
                    this.avg_type='lin';
                case {'exp', 'exponential'}
                    this.avg_type='exp';
                otherwise
                    error(['Averaging type must be ''lin'' ' ...
                        '(''linear'') or ''exp'' (''exponential'')'])
            end
        end
        
        function set.n_avg(this, val)
            % The number of averages should be integer not smaller than one
            this.n_avg=max(1, round(val));
        end
        
    end
end

