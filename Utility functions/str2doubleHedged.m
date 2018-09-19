function [val,str_spec]=str2doubleHedged(str)
    conv_str=str2double(str);
    if ~isnan(conv_str)
        val=conv_str;
        str_spec='%e';
    else
        val=str;
        str_spec='%s';
    end
end