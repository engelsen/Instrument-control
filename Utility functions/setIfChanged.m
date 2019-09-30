% Shorthand for an assignment with AbortSet=true.  

function is_changed = setIfChanged(Obj, prop, val)
    if length(Obj) > 1
        
        % Span over the array of objects
        is_changed = arrayfun(@(x)setIfChanged(x, prop, val), Obj);
        return
    end

    is_changed = ~isequal(Obj.(prop), val);
    
    if is_changed
        Obj.(prop) = val;
    end
end

