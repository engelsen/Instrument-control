% Find matlab.ui.Figure handle in structure or class instance
function fig_handle = findfigure(obj)
    if isstruct(obj)
        prop_names = fieldnames(obj);
    else
        prop_names = properties(obj);
    end
    % Try to find the figure among the properties
    figure_ind=cellfun(@(x) isa(obj.(x),'matlab.ui.Figure'), prop_names);
    if any(figure_ind)
        % Returns the 1-st figure among the found
        fig_names = prop_names(figure_ind);
        fig_handle=obj.(fig_names{1});
    else
        fig_handle=[];
    end
end

