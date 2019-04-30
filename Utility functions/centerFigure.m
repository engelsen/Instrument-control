% Find figure within the object and move it to the center of the screen

function centerFigure(Obj)

    % Find figure within the object if the object is not a figure itself
    Fig = findFigure(Obj);
    
    if isempty(Fig)
        return
    end
    
    fig_w = Fig.Position(3);
    fig_h = Fig.Position(4);
    
    R = groot();
    
    % Display the figure window in the center of the screen
    fig_x = R.ScreenSize(3)/2-fig_w/2;
    fig_y = R.ScreenSize(4)/2-fig_h/2;
    
    Fig.Position(1:2) = [fig_x, fig_y];
end

