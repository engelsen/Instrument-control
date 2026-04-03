function bp = observerExample()
%OBSERVEREXAMPLE An example using uix.FigureObserver to respond to theme 
% changes in the figure ancestor of a box panel.

% Copyright 2024 The MathWorks, Inc.

% Create an unrooted box panel.
bp = uix.BoxPanel( 'Parent', [], ...
    'Units', 'normalized', ...
    'Position', [0.25, 0.25, 0.50, 0.50], ...
    'DeleteFcn', @onBoxPanelDeleted );

% Add a label.
lb = uilabel( 'Parent', bp, ...
    'HorizontalAlignment', 'center', ...
    'Text', '' );

% Create a figure observer for the box panel.
fo = uix.FigureObserver( bp );

% Create a listener for the FigureChanged event.
figureChangedListener = listener( fo, 'FigureChanged', @onFigureChanged );

% Ensure that the listener persists.
setappdata( bp, 'FigureChangedListener', figureChangedListener )

% Initialize a listener for the figure ancestor ThemeChanged event.
themeChangedListener = event.listener.empty( 0, 1 );

    function onFigureChanged( ~, e )

        % Renew the theme changed listener.
        newFigure = e.NewFigure;
        if ~isempty( newFigure )
            themeChangedListener = listener( newFigure, ...
                'ThemeChanged', @onThemeChanged );
            setappdata( bp, 'ThemeChangedListener', themeChangedListener )
            onThemeChanged( newFigure )
        end % if

    end % onFigureChanged

    function onThemeChanged( s, ~ )

        if ~isempty( s.Theme )
            lb.Text = s.Theme.Name;
        else
            lb.Text = 'No theme detected.';
        end % if

    end % onThemeChanged

    function onBoxPanelDeleted( ~, ~ )

        % Tidy up listeners.
        delete( getappdata( bp, 'FigureChangedListener' ) )
        if isappdata( bp, 'ThemeChangedListener' )
            delete( getappdata( bp, 'ThemeChangedListener' ) )
        end % if

    end % onBoxPanelDeleted

end % observerExample