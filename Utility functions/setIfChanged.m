% Shorthand for an assignment with AbortSet=true.  

function is_changed = setIfChanged(Obj, prop, val)
    is_changed = ~isequal(Obj.(prop), val);
    
    if is_changed
        Obj.(prop) = val;
    end
end

