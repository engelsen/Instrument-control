function varargout = dockExample()
%DOCKEXAMPLE An example of using the panelbox dock/undock functionality

%  Copyright 2009-2024 The MathWorks, Inc.

% Create a new figure window and a horizontal layout.
f = figure( 'Name', 'Dock/Undock Example', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off', ...
    'CloseRequestFcn', @onCloseAll );
hbox = uix.HBox( 'Parent', f );

% Add three box panels.
boxPanels(1) = uix.BoxPanel( 'Parent', hbox, 'Title', 'Panel 1', ...
    'UserData', 1 );
boxPanels(2) = uix.BoxPanel( 'Parent', hbox, 'Title', 'Panel 2', ...
    'UserData', 2 );
boxPanels(3) = uix.BoxPanel( 'Parent', hbox, 'Title', 'Panel 3', ...
    'UserData', 3 );

% Place a button in each box panel.
uicontrol( 'Parent', boxPanels(1), 'Style', 'pushbutton', ...
    'String', 'Button 1' )
uicontrol( 'Parent', boxPanels(2), 'Style', 'pushbutton', ...
    'String', 'Button 2' )
uicontrol( 'Parent', boxPanels(3), 'Style', 'pushbutton', ...
    'String', 'Button 3' )

% Connect the dock callback to each box panel.
boxPanels(1).DockFcn = {@onDock, 1};
boxPanels(2).DockFcn = {@onDock, 2};
boxPanels(3).DockFcn = {@onDock, 3};

% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

    function onDock( ~, ~, panelIdx )

        % Toggle the Docked status of the panel.
        boxPanels(panelIdx).Docked = ~boxPanels(panelIdx).Docked;

        if boxPanels(panelIdx).Docked
            % Put it back in the layout.
            newFigure = boxPanels(panelIdx).Parent;
            boxPanels(panelIdx).Parent = hbox;
            delete( newFigure )
            [~, sortIdx] = sort( [hbox.Contents.UserData] );
            hbox.Contents = hbox.Contents(sortIdx);
        else
            % Take it out of the layout.
            panelPosition = getpixelposition( boxPanels(panelIdx) );
            newFigure = figure( 'Name', boxPanels(panelIdx).Title, ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'NumberTitle', 'off', ...
                'CloseRequestFcn', {@onDock, panelIdx} );
            newFigure.Position(3:4) = panelPosition(3:4);
            set( boxPanels(panelIdx), 'Parent', newFigure, ...
                'Units', 'normalized', ...
                'Position', [0, 0, 1, 1] )
        end % if

    end % onDock

    function onCloseAll( ~, ~ )

        for k = 1 : numel( boxPanels )
            boxPanelFigure = ancestor( boxPanels(k), 'figure' );
            if ~isempty( boxPanelFigure )
                delete( boxPanelFigure )
            end % if
        end % for

    end % onCloseAll

end % dockExample