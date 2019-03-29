% Shorthand for an assignment with AbortSet=true.  

function setIfChanged(Obj, prop, val)
    if ~isequal(Obj.(prop), val)
        Obj.(prop) = val;
    end
end

