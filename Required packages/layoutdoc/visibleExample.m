function varargout = visibleExample()
%VISIBLEEXAMPLE Showing/hiding a panel
%
%   This example opens a simple user-interface with a panel full of
%   buttons. We can then show/hide the entire panel in one go. Note
%   that the previous state of the buttons is preserved.

%  Copyright 2009-2024 The MathWorks, Inc.

%% Create a new figure window and add a box panel.
f = figure( 'Name', 'Visible Example', ...    
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'NumberTitle', 'off' );
f.Position(3:4) = [300, 350];
panel = uix.BoxPanel( 'Parent', f, 'Title', 'Box Panel', 'FontSize', 12 );

%% Put some buttons inside the panel.
% First, create a vertical button box to hold the buttons.
box = uix.VButtonBox( 'Parent', panel, 'ButtonSize', [80, 30] );

% Place a selection of buttons with mixed visibilities inside the button 
% box.
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 1' )
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 2' )
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 3', ...
    'Visible', 'off' )
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 4' )
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 5', ...
    'Visible', 'off' )
uicontrol( 'Parent', box, 'Style', 'pushbutton', 'String', 'Button 6' )

%% Toggle the visibility of the box panel.
panel.Visible = 'off';

%% Restore the box panel visibility.
% Note that the original Visible state of each button has been preserved.
panel.Visible = 'on';

%% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

end % visibleExample