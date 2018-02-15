function val=str2doubleHedged(str)
    if ~isnan(str2double(str))
        val=str2double(str);
    else
        val=str;
    end
end