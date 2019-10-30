% Check if the object is Axes or UIAxes

function bool = isaxes(Obj)
    bool = isa(Obj, 'matlab.graphics.axis.Axes') ...
        || isa(Obj, 'matlab.ui.control.UIAxes');
end

