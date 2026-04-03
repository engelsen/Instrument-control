function obj = Empty( varargin )
%uix.Empty  Create an empty space
%
%   obj = uix.Empty() creates an empty space that can be used to add gaps
%   between elements in layouts.
%
%   obj = uix.Empty(param,value,...) also sets one or more property
%   values.
%
%   See the <a href="matlab:doc uix.Empty">documentation</a> for more detail and the list of properties.
%
%   Examples:
%   >> f = figure();
%   >> box = uix.HBox( 'Parent', f );
%   >> uicontrol( 'Parent', box, 'Background', 'r' )
%   >> uix.Empty( 'Parent', box )
%   >> uicontrol( 'Parent', box, 'Background', 'b' )

%  Copyright 2009-2024 The MathWorks, Inc.

% Create uicontainer
obj = matlab.ui.container.internal.UIContainer( 'Tag', 'empty', varargin{:} );

% Create property for Parent listener
p = addprop( obj, 'ParentListener' );
p.Hidden = true;

% Create Parent listener
obj.ParentListener = event.proplistener( obj, ...
    findprop( obj, 'Parent' ), 'PostSet', @(~,~)onParentChanged(obj) );

% Create property for Parent color listener
p = addprop( obj, 'ParentColorListener' );
p.Hidden = true;

% Create properties for FigureObserver and a corresponding listener
p = addprop( obj, 'FigureObserver' );
p.Hidden = true;
obj.FigureObserver = uix.FigureObserver( obj );
p = addprop( obj, 'FigureChangedListener' );
p.Hidden = true;
obj.FigureChangedListener = event.listener( obj.FigureObserver, ...
    'FigureChanged', @(~, ~) onFigureChanged( obj ) );

% Create property for ancestor theme listener
p = addprop( obj, 'AncestorThemeListener' );
p.Hidden = true;

% Initialize color and listeners
updateColor( obj )
updateListener( obj )
updateAncestorThemeListener( obj )

end % uix.Empty

function onParentChanged( obj )
%onParentColorChanged  Event handler

% Update color and listener
updateColor( obj )
updateListener( obj )

end % onParentChanged

function onParentColorChanged( obj )
%onParentColorChanged  Event handler

% Update color
updateColor( obj )

end % onParentColorChanged

function name = getColorProperty( obj )
%getColorProperty  Get color property

name = '';
if isprop( obj, 'BackgroundColor' )
    name = 'BackgroundColor';    
elseif isprop( obj, 'Color' )
    name = 'Color';
end % if

end % getColorProperty

function updateColor( obj )
%updateColor  Set uicontainer BackgroundColor to match Parent

parent = obj.Parent;
if isempty( parent ), return, end
property = getColorProperty( parent );
if ~isempty( property )
    color = parent.( property );
    obj.BackgroundColor_I = color;
end

end % updateColor

function updateListener( obj )
%updateListener  Create listener to parent color property

parent = obj.Parent;
if isempty( parent )
    obj.ParentColorListener = [];
else
    property = getColorProperty( parent );
    metaprop = findprop( parent, property );
    if metaprop.SetObservable
        obj.ParentColorListener = event.proplistener( parent, ...
            metaprop, 'PostSet', @(~,~)onParentColorChanged(obj) );
    else
        obj.ParentColorListener = [];
    end % if
end % if

end % updateListener

function onFigureChanged( obj )
%onFigureChanged Update the ThemeChanged listener and the color

updateAncestorThemeListener( obj )
updateColor( obj )

end % onFigureChanged

function updateAncestorThemeListener( obj )
%updateAncestorThemeListener Create listener to figure ancestor theme
%property

f = ancestor( obj, 'figure' );
if isempty( f )
    obj.AncestorThemeListener = [];
else
    figureMetadata = ?matlab.ui.Figure;
    figureEventNames = {figureMetadata.EventList.Name};
    if isprop( f, 'Theme' ) && ismember( 'ThemeChanged', figureEventNames )
        obj.AncestorThemeListener = event.listener( f, 'ThemeChanged', ...
            @(~, ~) onThemeChanged( obj ) );
    else
        obj.AncestorThemeListener = [];
    end % if
end % if

end % updateAncestorThemeListener

function onThemeChanged( obj )
%onThemeChanged Respond to the ThemeChanged event

if strcmp( obj.BackgroundColorMode, 'manual' )
    return
else % 'auto'
    updateColor( obj )
end % if

end % onThemeChanged