function varargout = axesInsideLayouts()
%AXESINSIDELAYOUTS Axes inside layouts
% This example demonstrates how axes are affected by being placed into
% layouts. The layouts take into account the 'PositionConstraint' property
% (from R2020a onwards) or the 'ActivePositionProperty' property (prior to
% R2020a) in order to determine whether to set the 'Position' or 
% 'OuterPosition' (default) property of the axes.

%  Copyright 2009-2024 The MathWorks, Inc.

%% Create a new figure window.
% Create a new figure window and remove the toolbar and menus.
f = figure( 'Name', 'Axes Inside Layouts', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off' );

%% Create the layout.
% The layout involves two axes side by side. This is done using a
% flexible horizontal box. The left-hand axes is left with the
% 'PositionConstraint' property set to 'outerposition', but the right-hand 
% axes is switched to use 'innerposition'.
hb = uix.HBoxFlex( 'Parent', f, 'Spacing', 3 );
axes1 = axes( 'Parent', hb );
axes2 = axes( 'Parent', hb );
if isprop( axes1, 'PositionConstraint' )
    axes1.PositionConstraint = 'outerposition';
    axes2.PositionConstraint = 'innerposition';
else
    axes1.ActivePositionProperty = 'outerposition';
    axes2.ActivePositionProperty = 'position';
end % if
hb.Widths = [-2, -1];

%% Fill the axes.
% Using 'OuterPosition' (left-hand axes) is the normal mode and looks good
% for virtually any plot type. Using 'InnerPosition' is only really useful 
% for 2D plots with the axes turned off, such as images.
x = membrane( 1, 15 );
surf( axes1, x );
lighting( axes1, 'gouraud' )
shading( axes1, 'interp' )
l = light( 'Parent', axes1 );
camlight( l, 'head' )
axis( axes1, 'tight' )

imagesc( x, 'Parent', axes2 );
set( axes2, 'XTickLabel', [], 'YTickLabel', [] );

%% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = f;
end % if

end % axesInsideLayouts