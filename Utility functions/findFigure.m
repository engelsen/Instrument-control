% Find matlab.ui.Figure handle in structure or class instance

function Fig = findFigure(Obj)
    
    % First check if the object is empty
    if isempty(Obj)
        Fig = [];
        return
    end

    % Check if the object itself is a figure
    if isa(Obj, 'matlab.ui.Figure')
        Fig = Obj;
        return
    end
    
    % If the object contains 'Gui' property, search over it instead of the
    % object itself.
    gui_prop_name_list = {'gui', 'Gui', 'GUI'};
    ind = ismember(gui_prop_name_list, properties(Obj));
    if nnz(ind) == 1
        tag = gui_prop_name_list{ind};
        Fig = findFigure(Obj.(tag));
        return
    end
    
    % Find figure among the object properties
    if isstruct(Obj)
        prop_names = fieldnames(Obj);
    else
        if isvalid(Obj)
            prop_names = properties(Obj);
        else
            Fig = [];
            return
        end
    end
    
    % Try to find the figure among the properties
    figure_ind = cellfun(@(x) isa(Obj.(x),'matlab.ui.Figure'), prop_names);
    if any(figure_ind)
        
        % Returns the 1-st figure among those found
        fig_names = prop_names(figure_ind);
        Fig = Obj.(fig_names{1});
    else
        Fig = [];
    end
end

