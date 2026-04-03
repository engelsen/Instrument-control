function varargout = layoutHierarchy()
%LAYOUTHIERARCHY A hierarchy of layouts example
% This example shows how to use layouts within other layouts to achieve
% more complex user interface designs with the right mix of variable and
% fixed sized components.

%  Copyright 2009-2024 The MathWorks, Inc.

%% Create a new figure window.
% Create a new figure window and remove the default toolbar and menus.
f = figure( 'Name', 'A Layout Hierarchy Example', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off', ...
    'Position', 400 * ones( 1, 4 ) );

%% Create the first layout (a vertical box).
% Inside this vertical box we place the axes.
vb = uix.VBox( 'Parent', f );
axes( 'Parent', vb )

%% Create the second layout (a horizontal box).
% Inside this horizontal box we place two buttons.
hb = uix.HButtonBox( 'Parent', vb, ...
    'Padding', 5 );
uicontrol( 'Parent', hb, ...
    'Style', 'pushbutton', ...
    'String', 'Button 1' )
uicontrol( 'Parent', hb, ...
    'Style', 'pushbutton', ...
    'String', 'Button 2' )

%% Set the vertical sizes.
% We want the axes to resize with the figure window, so we set the first
% height to be -1 (which means variable size with weight 1). We want the
% buttons to remain with a fixed height as the figure window is resized,
% so we set the second height to 35 (a fixed height of 35 pixels).
vb.Heights = [-1, 35];

%% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

end % layoutHierarchy