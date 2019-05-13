function axesToClipboard(Axes)
    pos = [0, 0, Axes.OuterPosition(3:4)];

    %Creates a new invisible figure with new axes
    NewFig = figure( ...
        'Visible',      'off', ...
        'Units',        Axes.Units, ...
        'Position',     pos);

    NewAxes = axes(NewFig, ...
        'Units',        Axes.Units, ...
        'OuterPosition',     pos);
    
    % Properties, always set to default
    NewAxes.Color = 'none';
    NewAxes.XColor = [0, 0, 0];
    NewAxes.YColor = [0, 0, 0];
    
    % Properties, copied from the source plot
    copy_prop_list = {'Box', 'BoxStyle', 'Clipping', 'ColorOrder', ...
        'FontAngle', 'FontName', 'FontSize', 'FontSmoothing', ...
        'FontUnits', 'FontWeight', 'GridAlpha', 'GridColor', ...
        'GridLineStyle', 'LineStyleOrder', 'LineWidth', ...
        'MinorGridAlpha', 'MinorGridColor', 'MinorGridLineStyle', ...
        'TickDir', 'TickLabelInterpreter', 'TickLength', 'TickDir', ...
        'XDir', 'XGrid', 'XLim', 'XMinorGrid', 'XMinorTick', ...
        'XScale', 'XTick', ...
        'YDir', 'YGrid', 'YLim', 'YMinorGrid', 'YMinorTick', ...
        'YScale', 'YTick'};
    
    for i = 1:length(copy_prop_list)
        if isprop(Axes, copy_prop_list{i})
            NewAxes.(copy_prop_list{i}) = Axes.(copy_prop_list{i});
        end
    end
    
    % Handling font sizes is different in axes and uiaxes, so copy it
    % specifically
    NewAxes.XAxis.FontSize = Axes.XAxis.FontSize;
    NewAxes.YAxis.FontSize = Axes.YAxis.FontSize;
    
    % Copy axes labels as these are handle objects
    NewAxes.XLabel = copy(Axes.XLabel);
    NewAxes.YLabel = copy(Axes.YLabel);
    
    try
        
        % Loose inset is an undocumented feature so we do not complain if
        % the code below does not work
        NewAxes.LooseInset = [0, 0, 0, 0];
    catch
    end
    
    % Copy the axes content
    for i = 1:length(Axes.Children)
        copyobj(Axes.Children(i), NewAxes);
    end

    %Prints the figure to the clipboard
    print(NewFig, '-clipboard', '-dbitmap');
    
    %Deletes the figure
    delete(NewFig);
end

