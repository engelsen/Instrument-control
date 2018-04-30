function [val,str_spec]=str2doubleHedged(str)
    if ~isnan(str2double(str))
        val=str2double(str);
        str_spec='%e';
    else
        val=str;
        str_spec='%s';
    end
end