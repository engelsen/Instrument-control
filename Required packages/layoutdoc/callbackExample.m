function varargout = callbackExample()
%CALLBACKEXAMPLE This example shows how to arrange layouts and controls in
%a simple app with a callback. The app contains a listbox with multiple
%color names, and a panel with background color controlled by the selection
%in the listbox.

% Copyright 2009-2024 The MathWorks, Inc.

%% Define the application data: the color names and corresponding RGB
% values.
colorNames = {'Red', 'Orange', 'Yellow', 'Green', ...
    'Blue', 'Indigo', 'Violet'};
colorValues = [1.0, 0.2, 0.2;
    1.0, 0.6, 0.2;
    1.0, 1.0, 0.4;
    0.6, 1.0, 0.6;
    0.2, 0.4, 1.0;
    0.4, 0.1, 0.6;
    0.7, 0.5, 1.0];

%% Create a new figure window and remove the toolbar and menus.
f = figure( 'Name', 'Callback Example', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off' );

%% Add a standard panel.
p = uix.Panel( 'Parent', f, ...
    'Title', 'Color Selection App', ...
    'TitlePosition', 'centertop' );

%% Add a flexible horizontal layout to the panel.
hbf = uix.HBoxFlex( 'Parent', p, ...
    'Spacing', 5, ...
    'Padding', 5 );

%% Add the listbox and panel.
lb = uicontrol( 'Parent', hbf, ...
    'Style', 'listbox', ...
    'String', colorNames, ...    
    'Callback', @onColorSelected );
c = uipanel( 'Parent', hbf, ...
    'BorderType', 'none', ...
    'Title', ['Selected Color: ', colorNames{1}], ...    
    'FontSize', 12, ...
    'BackgroundColor', colorValues(1, :) );

% Adjust the layout widths.
hbf.Widths = [-1, -3];

%% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

    function onColorSelected( ~, ~ )

        % Obtain the index of the selected color from the listbox.
        selectionIdx = lb.Value;

        % Update the panel.
        newColor = colorValues(selectionIdx, :);
        set( c, 'BackgroundColor', newColor, ...
            'Title', ['Selected Color: ', colorNames{selectionIdx}] )

    end % onColorSelected

end % callbackExample