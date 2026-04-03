classdef TabPanel < uix.Container & uix.mixin.Container
    %uix.TabPanel  Tab panel
    %
    %  p = uix.TabPanel(p1,v1,p2,v2,...) constructs a tab panel and sets
    %  parameter p1 to value v1, etc.
    %
    %  A tab panel shows one of its contents and hides the others according
    %  to which tab is selected.
    %
    %  From R2014b, MATLAB provides uitabgroup and uitab as standard
    %  components.  Consider using uitabgroup and uitab for new code if
    %  these meet your requirements.
    %
    %  See also: uitabgroup, uitab, uix.CardPanel

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( Access = public, Dependent, AbortSet )
        ForegroundColor % tab text color [RGB]
        Selection % selection
        TabContextMenus % tab context menus
        TabEnables % tab enable states
        TabLocation % tab location [top|bottom|left|right]
        TabTitles % tab titles
    end

    properties
        SelectionChangedFcn = '' % selection change callback
    end

    properties( Access = public, AbortSet, Hidden )
        ForegroundColor_I = get( 0, 'DefaultUitabForegroundColor' ) % backing for ForegroundColor
        ForegroundColorMode = 'auto' % ForegroundColor mode [auto|manual]
    end

    properties ( GetAccess = ?matlab.unittest.TestCase, SetAccess = private )
        TabGroup % tab group
    end

    properties( Access = private )
        ShadowTabGroup % tab group
        SelectionChangedListener % listener
        TabEnables_ = cell( 0, 1 ) % backing for TabEnables
    end

    properties( Constant, Access = private )
        DummyControl = matlab.ui.control.UIControl() % dummy uicontrol
        FontAngle_ = get( 0, 'DefaultUicontrolFontAngle' ) % backing for FontAngle
        FontName_ = get( 0, 'DefaultUicontrolFontName' ) % backing for FontName
        FontSize_ = get( 0, 'DefaultUicontrolFontSize' ) % backing for FontSize
        FontWeight_ = get( 0, 'DefaultUicontrolFontWeight' ) % backing for FontWeight
        FontUnits_ = get( 0, 'DefaultUicontrolFontUnits' ) % backing for FontUnits
        HighlightColor_ = [1 1 1] % backing for HighlightColor
        ShadowColor_ = [0.7 0.7 0.7] % backing for ShadowColor
    end

    properties( Access = public, Dependent, Hidden )
        FontAngle % font angle
        FontName % font name
        FontSize % font size
        FontWeight % font weight
        FontUnits % font weight
        HighlightColor % border highlight color [RGB]
        ShadowColor % border shadow color [RGB]
        TabWidth % tab width
    end % deprecated

    events( NotifyAccess = private )
        SelectionChanged % selection changed
    end

    methods

        function obj = TabPanel( varargin )
            %uix.TabPanel  Tab panel constructor
            %
            %  p = uix.TabPanel() constructs a tab panel.
            %
            %  p = uix.TabPanel(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.

            % Create tab groups
            tabGroup = matlab.ui.container.TabGroup( ...
                'Internal', true, 'Parent', obj, 'Visible', 'off', ...
                'SelectionChangedFcn', @obj.onTabSelected );
            if isprop( tabGroup, 'AutoResizeChildren' )
                tabGroup.AutoResizeChildren = 'off';
            end
            shadowTabGroup = matlab.ui.container.TabGroup( ...
                'Internal', true, 'Parent', obj, ...
                'Units', 'normalized', 'Position', [-2 -2 1 1], ...
                'SizeChangedFcn', @obj.onTabGroupSizeChanged );
            if isprop( shadowTabGroup, 'AutoResizeChildren' )
                shadowTabGroup.AutoResizeChildren = 'off';
            end

            % Store properties
            obj.TabGroup = tabGroup;
            obj.ShadowTabGroup = shadowTabGroup;

            % Create listeners
            selectionChangedListener = event.listener( obj, ...
                'SelectionChanged', @obj.onSelectionChanged );

            % Store listeners
            obj.SelectionChangedListener = selectionChangedListener;

            % Set properties
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end

        end % constructor

    end % structors

    methods

        function value = get.ForegroundColor( obj )

            value = obj.ForegroundColor_I;

        end % get.ForegroundColor

        function set.ForegroundColor( obj, value )

            try
                obj.ForegroundColor_I = value; % delegate
                obj.ForegroundColorMode = 'manual'; % flip
            catch
                throwAsCaller( MException( 'uix:InvalidPropertyValue', ...
                    'Property ''ForegroundColor'' must be a colorspec.' ) )
            end

        end % set.ForegroundColor

        function set.ForegroundColor_I( obj, value )

            try
                obj.DummyControl.ForegroundColor = value; % colorspec
                value = obj.DummyControl.ForegroundColor; % rgb
                obj.ForegroundColor_I = value; % store
                obj.redrawTabs() % apply
            catch
                throwAsCaller( MException( 'uix:InvalidPropertyValue', ...
                    'Property ''ForegroundColor_I'' must be a colorspec.' ) )
            end

        end % set.ForegroundColor_I

        function set.ForegroundColorMode( obj, value )

            try
                value = char( value ); % convert
                assert( ismember( value, {'auto','manual'} ) ) % compare
                obj.ForegroundColorMode = value; % store
            catch
                throwAsCaller( MException( 'uix:InvalidPropertyValue', ...
                    'Property ''ForegroundColorMode'' must be ''auto'' or ''manual''.' ) )
            end

        end % set.ForegroundColorMode

        function value = get.Selection( obj )

            tabGroup = obj.TabGroup;
            value = find( tabGroup.Children == tabGroup.SelectedTab );
            if isempty( value ), value = 0; end

        end % get.Selection

        function set.Selection( obj, newValue )

            % Select
            oldValue = obj.Selection;
            tabGroup = obj.TabGroup;
            shadowTabGroup = obj.ShadowTabGroup;
            try
                assert( isscalar( newValue ) )
                tabGroup.SelectedTab = tabGroup.Children(newValue);
                shadowTabGroup.SelectedTab = shadowTabGroup.Children(newValue);
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''Selection'' must be between 1 and the number of tabs.' )
            end

            % Raise event
            notify( obj, 'SelectionChanged', ...
                uix.SelectionChangedData( oldValue, newValue ) )

            % Show and hide
            contents = obj.Contents_;
            uix.setVisible( contents(oldValue), 'off' ) % hide old selection
            uix.setVisible( contents(newValue), 'on' ) % show new selection

            % Mark as dirty
            obj.Dirty = true;

        end % set.Selection

        function value = get.TabEnables( obj )

            value = obj.TabEnables_;

        end % get.TabEnables

        function set.TabEnables( obj, value )

            % Convert
            try
                value = cellstr( value );
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''TabEnables'' must be a cell array of strings ''on'' or ''off'', one per tab.' )
            end

            % Reshape
            value = value(:);

            % Check
            tabs = obj.TabGroup.Children;
            assert( isequal( numel( value ), numel( tabs ) ) && ...
                all( ismember( value, {'on','off'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabEnables'' must be a cell array of strings ''on'' or ''off'', one per tab.' )

            % Set
            obj.TabEnables_ = value;

            % Redraw tabs
            obj.redrawTabs()

        end % set.TabEnables

        function value = get.TabLocation( obj )

            value = obj.TabGroup.TabLocation;

        end % get.TabLocation

        function set.TabLocation( obj, value )

            % Convert
            try
                value = char( value );
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''TabLocation'' must be ''top'', ''bottom'', ''left'' or ''right''.' )
            end

            % Check
            assert( ismember( value, {'top','bottom','left','right'} ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabLocation'' must be ''top'', ''bottom'', ''left'' or ''right''.' )

            % Set
            obj.TabGroup.TabLocation = value;
            obj.ShadowTabGroup.TabLocation = value;

            % Mark as dirty
            obj.Dirty = true;

        end % set.TabLocation

        function value = get.TabTitles( obj )

            value = get( obj.TabGroup.Children, {'Title'} );

        end % get.TabTitles

        function set.TabTitles( obj, value )

            % Convert
            try
                value = cellstr( value );
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''TabTitles'' must be a cell array of strings, one per tab.' )
            end

            % Reshape
            value = value(:);

            % Check
            tabs = obj.TabGroup.Children;
            shadowTabs = obj.ShadowTabGroup.Children;
            assert( isequal( numel( value ), numel( tabs ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabTitles'' must be a cell array of strings, one per tab.' )

            % Set
            for ii = 1:numel( tabs )
                tabs(ii).Title = value{ii};
                shadowTabs(ii).Title = value{ii};
            end

        end % set.TabTitles

        function value = get.TabContextMenus( obj )

            value = get( obj.TabGroup.Children, {'UIContextMenu'} );

        end % get.TabContextMenus

        function set.TabContextMenus( obj, value )

            % Reshape
            value = value(:);

            % Check
            tabs = obj.TabGroup.Children;
            assert( iscell( value ) && ...
                numel( value ) == numel( tabs ) && ...
                all( cellfun( @iscontextmenu, value(:) ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''TabContextMenus'' must be a cell array of context menus, one per tab.' )

            % Set
            for ii = 1:numel( tabs )
                tabs(ii).UIContextMenu = value{ii};
            end

        end % set.TabContextMenus

        function set.SelectionChangedFcn( obj, value )

            % Check
            if ischar( value ) || isa( value, 'string' ) % string
                % OK
            elseif isa( value, 'function_handle' ) && ...
                    isscalar( value ) % function handle
                % OK
            elseif iscell( value ) && ndims( value ) == 2 && ...
                    size( value, 1 ) == 1 && size( value, 2 ) > 0 && ...
                    isa( value{1}, 'function_handle' ) && ...
                    isscalar( value{1} ) %#ok<ISMAT> % cell callback
                % OK
            else
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''SelectionChangedFcn'' must be a valid callback.' )
            end

            % Set
            obj.SelectionChangedFcn = value;

        end % set.SelectionChangedFcn

    end % accessors

    methods

        function value = get.FontAngle( obj )

            value = obj.FontAngle_;

        end % get.FontAngle

        function set.FontAngle( ~, ~ ) % removed

        end % set.FontAngle

        function value = get.FontName( obj )

            value = obj.FontName_;

        end % get.FontName

        function set.FontName( ~, ~ ) % removed

        end % set.FontName

        function value = get.FontSize( obj )

            value = obj.FontSize_;

        end % get.FontSize

        function set.FontSize( ~, ~ ) % removed

        end % set.FontSize

        function value = get.FontWeight( obj )

            value = obj.FontWeight_;

        end % get.FontWeight

        function set.FontWeight( ~, ~ ) % removed

        end % set.FontWeight

        function value = get.FontUnits( obj )

            value = obj.FontUnits_;

        end % get.FontUnits

        function set.FontUnits( ~, ~ ) % removed

        end % set.FontUnits

        function value = get.HighlightColor( obj )

            value = obj.HighlightColor_;

        end % get.HighlightColor

        function set.HighlightColor( ~, ~ ) % removed

        end % set.HighlightColor

        function value = get.ShadowColor( obj )

            value = obj.ShadowColor_;

        end % get.ShadowColor

        function set.ShadowColor( ~, ~ ) % removed

        end % set.ShadowColor

        function value = get.TabWidth( ~ )

            value = -1;

        end % get.TabWidth

        function set.TabWidth( ~, ~ ) % removed

        end % set.TabWidth

    end % deprecated accessors

    methods( Access = protected )

        function redraw( obj )
            %redraw  Redraw

            % Skip if no contents
            i = obj.Selection;
            if i == 0, return, end

            % Compute positions
            g = obj.TabGroup;
            s = obj.ShadowTabGroup;
            f = ancestor( s, 'figure' );
            sb = hgconvertunits( f, [0 0 1 1], 'normalized', 'pixels', s );
            t = s.SelectedTab;
            tb = hgconvertunits( f, [0 0 1 1], 'normalized', 'pixels', t );
            pa = obj.Padding_;
            switch s.TabLocation
                case 'top'
                    m = (sb(3)-tb(3))/2;
                    gp = sb + (tb(4)+m) * [0 1 0 -1];
                    cp = tb + [m m 0 0] + pa * [1 1 -2 -2];
                case 'bottom'
                    m = (sb(3)-tb(3))/2;
                    gp = sb + (tb(4)+m) * [0 0 0 -1];
                    cp = tb + [m sb(4)-tb(4)-m 0 0] + pa * [1 1 -2 -2];
                case 'left'
                    m = (sb(4)-tb(4))/2;
                    gp = sb + (tb(3)+m) * [0 0 -1 0];
                    cp = tb + [sb(3)-tb(3)-m m 0 0] + pa * [1 1 -2 -2];
                case 'right'
                    m = (sb(4)-tb(4))/2;
                    gp = sb + (tb(3)+m) * [1 0 -1 0];
                    cp = tb + [m m 0 0] + pa * [1 1 -2 -2];
            end
            gp = max( gp, [1 1 0 0] ); % floor
            cp = max( cp, [1 1 0 0] ); % floor

            % Redraw tab group and contents
            uix.setPosition( g, gp, 'pixels' );
            uix.setPosition( obj.Contents_(i), cp, 'pixels' )

        end % redraw

        function addChild( obj, child )
            %addChild  Add child
            %
            %  c.addChild(d) adds the child d to the container c.

            % Call superclass method
            addChild@uix.mixin.Container( obj, child )

            % Show tab group
            tabGroup = obj.TabGroup;
            tabGroup.Visible = 'on';

            % Create new tab
            shadowTabGroup = obj.ShadowTabGroup;
            tabs = tabGroup.Children;
            n = numel( tabs );
            tab = uitab( 'Parent', tabGroup, ...
                'Title', sprintf( 'Tab %d', n+1 ), ...
                'ForegroundColor', obj.ForegroundColor ); %#ok<NASGU>
            shadowTab = uitab( 'Parent', shadowTabGroup, ...
                'Title', sprintf( 'Tab %d', n+1 ) );
            if isprop( shadowTab, 'AutoResizeChildren' )
                shadowTab.AutoResizeChildren = 'off';
            end
            shadowTab.SizeChangedFcn = @obj.onTabSizeChanged;
            obj.TabEnables_(n+1,:) = {'on'};

            % Show and hide
            tabGroup.Visible = 'on';
            if obj.Contents_(obj.Selection) ~= child % not selected
                uix.setVisible( child, 'off' ) % hide
            elseif obj.G1136196 && strcmp( child.Visible, 'off' ) % bug
                on = @() eq( obj.Contents(obj.Selection), child );
                uix.setVisible( child, on, 0.02 ) % future show
            else % selected
                uix.setVisible( child, 'on' ) % show
            end

        end % addChild

        function removeChild( obj, child )
            %removeChild  Remove child
            %
            %  c.removeChild(d) removes the child d from the container c.

            % Capture old state
            tabGroup = obj.TabGroup;
            shadowTabGroup = obj.ShadowTabGroup;
            oldContents = obj.Contents_;
            oldSelection = obj.Selection;

            % Call superclass method
            removeChild@uix.mixin.Container( obj, child )

            % Remove tab
            index = find( oldContents == child );
            delete( tabGroup.Children(index) )
            delete( shadowTabGroup.Children(index) )
            obj.TabEnables_(index,:) = [];

            % Show and hide
            if index == oldSelection % removing selected
                newContents = obj.Contents_;
                newSelection = obj.Selection;
                if newSelection == 0 % none left
                    obj.TabGroup.Visible = 'off';
                else % switch
                    uix.setVisible( newContents(newSelection), 'on' ) % show new selection
                end
            end

        end % removeChild

        function reorder( obj, indices )
            %reorder  Reorder contents
            %
            %  c.reorder(i) reorders the container contents using indices
            %  i, c.Contents = c.Contents(i).

            % Call superclass method
            reorder@uix.mixin.Container( obj, indices )

            % Reorder
            tabGroup = obj.TabGroup;
            tabGroup.Children = tabGroup.Children(indices,:);
            shadowTabGroup = obj.ShadowTabGroup;
            shadowTabGroup.Children = shadowTabGroup.Children(indices,:);
            obj.TabEnables_ = obj.TabEnables_(indices,:);

        end % reorder

        function reparent( obj, oldFigure, newFigure )
            %reparent  Reparent container
            %
            %  c.reparent(a,b) reparents the container c from the figure a
            %  to the figure b.

            % Call superclass method
            reparent@uix.mixin.Container( obj, oldFigure, newFigure )

            % Move context menus to new figure
            if ~isequal( oldFigure, newFigure )
                contextMenus = vertcat( obj.TabContextMenus{:} );
                set( contextMenus, 'Parent', newFigure );
            end

        end % reparent

    end % template methods

    methods( Access = protected, Static )

        function map = getThemeMap()
            %getThemeMap  Map class properties to theme attributes

            map = getThemeMap@uix.Container();
            map.ForegroundColor = '--mw-color-primary';

        end % getThemeMap

    end % protected static methods

    methods( Access = private )

        function redrawTabs( obj )
            %redrawTabs  Redraw tabs

            enableColor = obj.ForegroundColor_I;
            if mean( enableColor ) > 0.5 % light
                disableColor = 1/3 * enableColor;
            else % dark
                disableColor = 2/3 + 1/3 * enableColor;
            end
            tf = strcmp( obj.TabEnables_, 'on' );
            tabs = obj.TabGroup.Children;
            set( tabs(tf), 'ForegroundColor', enableColor )
            set( tabs(~tf), 'ForegroundColor', disableColor )

        end % redrawTabs

    end % helper methods

    methods( Access = private )

        function onTabSelected( obj, ~, eventData )
            %onTabSelected  Event handler for interactive tab selection
            %
            %  onTabSelected shows the child of the selected tab and
            %  prevents selection of disabled tabs.

            % Find old and new selections
            tabGroup = obj.TabGroup;
            shadowTabGroup = obj.ShadowTabGroup;
            oldSelection = find( tabGroup.Children == eventData.OldValue );
            newSelection = find( tabGroup.Children == eventData.NewValue );

            if strcmp( obj.TabEnables_{newSelection}, 'off' )

                % Revert
                tabGroup.SelectedTab = eventData.OldValue;
                shadowTabGroup.SelectedTab = shadowTabGroup.Children(oldSelection);

            else

                % Synchronize
                shadowTabGroup.SelectedTab = shadowTabGroup.Children(newSelection);

                % Raise event
                notify( obj, 'SelectionChanged', ...
                    uix.SelectionChangedData( oldSelection, newSelection ) )

                % Show and hide
                contents = obj.Contents_;
                uix.setVisible( contents(oldSelection), 'off' ) % hide old selection
                uix.setVisible( contents(newSelection), 'on' ) % show new selection

                % Mark as dirty
                obj.Dirty = true;

            end

        end % onTabSelected

        function onSelectionChanged( obj, source, eventData )
            %onSelectionChanged  Event handler for selection
            %
            %  onSelectionChanged calls the SelectionChangedFcn when a
            %  SelectionChanged event is raised.

            callback = obj.SelectionChangedFcn;
            if ischar( callback ) && isequal( callback, '' )
                % do nothing
            elseif ischar( callback )
                feval( callback, source, eventData )
            elseif isa( callback, 'function_handle' )
                callback( source, eventData )
            elseif iscell( callback )
                feval( callback{1}, source, eventData, callback{2:end} )
            end

        end % onSelectionChanged

        function onTabGroupSizeChanged( ~, tabGroup, ~ )
            %onTabGroupSizeChanged  Remedial event handler
            %
            %  onTabGroupSizeChanged keeps the uitabgroup maximized within
            %  its container, despite the best efforts of
            %  matlab.ui.internal.WebTabGroupController et al.

            tabGroup.Position = [-2 -2 1 1]; % maximized

        end % onTabGroupSizeChanged

        function onTabSizeChanged( obj, tab, ~ )
            %onTabSizeChanged  Event handler for tab resize

            % Deprecated unselected tabs
            if obj.ShadowTabGroup.SelectedTab ~= tab, return, end

            % Mark as dirty
            obj.Dirty = true;

        end % onTabSizeChanged

    end % event handlers

end % classdef

function tf = iscontextmenu( o )
%iscontextmenu  Test for context menu
%
%  tf = iscontextmenu(o) returns true if o is a valid UIContextMenu value,
%  that is, a scalar context menu or an empty graphics placeholder

if isa( o, 'matlab.ui.container.ContextMenu' ) && isscalar( o ) % context menu
    tf = true;
elseif isequal( o, gobjects( 0 ) ) % graphics placeholder
    tf = true;
else % something else
    tf = false;
end

end % iscontextmenu