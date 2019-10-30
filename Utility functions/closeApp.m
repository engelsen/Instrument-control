% Delete App by closing its figure window

function closeApp(App)
    Fig = findFigure(App);
    
    if ~isempty(Fig)
        
        % Close the figure so that the cleanup procedure possibly defined 
        % by the user are executed
        close(Fig);
    else
        
        % Simply delete the object
        delete(App)
    end
end

