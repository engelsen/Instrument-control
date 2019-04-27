% Bring the figure contained in Obj on top of other windows and set focus
% to it

function setFocus(Obj)
    Fig = findFigure(Obj);
    Fig.Visible = 'off';
    Fig.Visible = 'on';
end

