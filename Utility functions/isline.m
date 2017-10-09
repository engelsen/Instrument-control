function bool=isline(linestyle)
bool=any(strcmpi({'-','--',':','-.','none'},linestyle));
end