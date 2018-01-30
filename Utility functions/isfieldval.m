% Checks if the structure (or class) has fields with particular values
% usage: isfieldval(structure, 'field1', value1, 'field2', value2, ...)
function bool = isfieldval(x, varargin)
    bool = true;
    for i=1:floor(length(varargin)/2)
        try
            tmp_bool = isequal(x.(varargin{2*i-1}), varargin{2*i});
        catch
            tmp_bool = false;
        end
        bool = bool & tmp_bool;
    end
end

