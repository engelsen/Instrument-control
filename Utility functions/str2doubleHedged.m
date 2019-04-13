function [val, str_spec] = str2doubleHedged(str)
    
    % Span over multiple inputs given as cell
    if iscell(str)
        val = cellfun(@str2doubleHedged, str, 'UniformOutput', false);
        return
    end
    
    conv_str = str2double(str);
    if ~isnan(conv_str)
        val = conv_str;
        str_spec = '%e';
    else
        val = str;
        str_spec = '%s';
    end
end