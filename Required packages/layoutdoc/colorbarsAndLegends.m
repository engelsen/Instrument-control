function varargout = colorbarsAndLegends()
%COLORBARSANDLEGENDS Axes with colorbars inside layouts
% This example demonstrates how to correctly layout axes that have
% associated legends or colorbars by grouping them together using a
% uicontainer.

%  Copyright 2009-2024 The MathWorks, Inc.

%% Create a new figure window.
% Create a new figure window and remove the toolbar and menus.
f = figure( 'Name', 'Axes Legends and Colorbars', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off' );

%% Create the layout.
% The layout involves two axes side by side. Each axes is placed into a
% uicontainer so that the legend and colorbar are grouped together with the
% axes.
vbox = uix.VBoxFlex( 'Parent', f, 'Spacing', 3 );
axes1 = axes( 'Parent', uicontainer( 'Parent', vbox ) );
axes2 = axes( 'Parent', uicontainer( 'Parent', vbox ) );

%% Add axes decorations.
% Give the first axes a colorbar and the second axes a legend.
surf( axes1, membrane( 1, 15 ) )
colorbar( axes1 )

theta = 0:360;
plot( axes2, theta, sind( theta ), theta, cosd( theta ), 'LineWidth', 2 )
legend( axes2, 'sin', 'cos', 'Location', 'northwestoutside' )

%% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

end % colorbarsAndLegends