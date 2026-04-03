function varargout = minimizeExample()
%MINIMIZEEXAMPLE An example of using the panelbox minimize/maximize

%  Copyright 2009-2025 The MathWorks, Inc.

figureWidth = 400;
maxPanelHeight = 100;

% Create the figure window and a vertical layout.
f = figure( 'Name', 'Minimize/Maximize Example', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off' );
vbox = uix.VBox( 'Parent', f );

% Add three box panels.
boxPanels(1) = uix.BoxPanel( 'Parent', vbox, 'Title', 'Panel 1' );
boxPanels(2) = uix.BoxPanel( 'Parent', vbox, 'Title', 'Panel 2' );
boxPanels(3) = uix.BoxPanel( 'Parent', vbox, 'Title', 'Panel 3' );
vbox.Heights = maxPanelHeight * [1, 1, 1];

% Place a button in each box panel.
uicontrol( 'Parent', boxPanels(1), 'Style', 'pushbutton', ...
    'String', 'Button 1' )
uicontrol( 'Parent', boxPanels(2), 'Style', 'pushbutton', ...
    'String', 'Button 2' )
uicontrol( 'Parent', boxPanels(3), 'Style', 'pushbutton', ...
    'String', 'Button 3' )

% Resize the figure window.
f.Position(3:4) = [figureWidth, sum( vbox.Heights )];

% Connect the minimize callback to each box panel.
boxPanels(1).MinimizeFcn = {@onMinimize, 1};
boxPanels(2).MinimizeFcn = {@onMinimize, 2};
boxPanels(3).MinimizeFcn = {@onMinimize, 3};

% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

    function onMinimize( ~, ~, panelIdx )

        % Retrieve the row heights from the vertical box layout.
        rowHeights = vbox.Heights;

        % Retrieve the figure position.
        figurePosition = f.Position;

        % Toggle the Minimize status of the panel.
        boxPanels(panelIdx).Minimized = ~boxPanels(panelIdx).Minimized;

        % Expand or collapse the corresponding panel.
        if boxPanels(panelIdx).Minimized
            rowHeights(panelIdx) = boxPanels(panelIdx).MinimizedHeight;
        else
            rowHeights(panelIdx) = maxPanelHeight;
        end % if
        vbox.Heights = rowHeights;

        % Resize the figure, keeping the top stationary.
        deltaHeight = figurePosition(4) - sum( vbox.Heights );
        f.Position = figurePosition + [0, deltaHeight, 0, -deltaHeight];

    end % onMinimize

end % minimizeExample