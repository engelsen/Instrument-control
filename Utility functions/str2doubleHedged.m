function [val, format] = str2doubleHedged(str)
    
    % Span over multiple inputs given as cell
    if iscell(str)
        val = cellfun(@str2doubleHedged, str, 'UniformOutput', false);
        return
    end
    
    conv_str = str2double(str);
    
    if ~isnan(conv_str)
        val = conv_str;
        
        % Determine the printed format type - float or integer and
        % fixed point or exponential
        is_float = contains(str, '.');
        is_exp = contains(str, {'e', 'E'});
        
        % Determine the precision: separate mantissa and exponent and count
        % the digits of mantissa
        num_str = regexp(strtrim(str), 'e|E', 'split');
        prec = length(regexp(num_str{1}, '\d'))-1;
        
        if prec >= 16
            warning(['Standard double type precision limit is reached ' ...
                'while converting the string ''%s''. ' ...
                'The converted numeric value may have lower precision ' ...
                'compare to that of the original string.'], str)
        end
        
        if is_float
            if is_exp
                format = sprintf('%%.%ie', prec);
            else
                format = sprintf('%%.%if', prec);
            end
        else
            format = '%i';
        end
    else
        val = str;
        format = '%s';
    end
end