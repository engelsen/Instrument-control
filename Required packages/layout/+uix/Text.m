classdef ( Hidden ) Text < matlab.mixin.SetGet
    %uix.Text  Text control
    %
    %  This class will be removed in a future release.
    %
    %  t = uix.Text(p1,v1,p2,v2,...) constructs a text control and sets
    %  parameter p1 to value v1, etc.
    %
    %  A text control adds functionality to a uicontrol of Style text:
    %  * Set VerticalAlignment to 'top', 'middle' or 'bottom'
    %  * Fire a Callback when the user clicks on the text
    %
    %  See also: uicontrol

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( Dependent )
        BackgroundColor
    end

    properties( Dependent, SetAccess = private )
        BeingDeleted
    end

    properties( Dependent )
        Callback
        DeleteFcn
        Enable
    end

    properties( Dependent, SetAccess = private )
        Extent
    end

    properties( Dependent )
        FontAngle
        FontName
        FontSize
        FontUnits
        FontWeight
        ForegroundColor
        HandleVisibility
        HorizontalAlignment
        Parent
        Position
        String
        Tag
        TooltipString
    end

    properties( Dependent, SetAccess = private )
        Type
    end

    properties( Dependent )
        UIContextMenu
        Units
        UserData
        VerticalAlignment
        Visible
    end

    properties( Access = private )
        Container % container
        Label % label
        VerticalAlignment_ = 'top' % backing for VerticalAlignment
        Dirty = false % flag
        FigureObserver % observer
        FigureListener % listener
    end

    methods

        function obj = Text( varargin )
            %uix.Text  Text control
            %
            %  t = uix.Text(p1,v1,p2,v2,...) constructs a text control and
            %  sets parameter p1 to value v1, etc.

            % Create graphics
            container = uicontainer( 'Parent', [], ...
                'Units', get( 0, 'DefaultUicontrolUnits' ), ...
                'Position', get( 0, 'DefaultUicontrolPosition' ), ...
                'SizeChangedFcn', @obj.onResized );
            label = uicontrol( 'Parent', container, ...
                'HandleVisibility', 'off', ...
                'Style', 'text', 'Units', 'pixels', ...
                'HorizontalAlignment', 'center', ...
                'Enable', 'inactive' );

            % Create observers and listeners
            figureObserver = uix.FigureObserver( container );
            figureListener = event.listener( figureObserver, ...
                'FigureChanged', @obj.onFigureChanged );

            % Store properties
            obj.Container = container;
            obj.Label = label;
            obj.FigureObserver = figureObserver;
            obj.FigureListener = figureListener;

            % Set properties
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end

        end % constructor

        function delete( obj )
            %delete  Destructor

            delete( obj.Container )

        end % destructor

    end % structors

    methods

        function value = get.BackgroundColor( obj )

            value = obj.Label.BackgroundColor;

        end % get.BackgroundColor

        function set.BackgroundColor( obj, value )

            obj.Container.BackgroundColor = value;
            obj.Label.BackgroundColor = value;

        end % set.BackgroundColor

        function value = get.BeingDeleted( obj )

            value = obj.Label.BeingDeleted;

        end % get.BeingDeleted

        function value = get.Callback( obj )

            value = obj.Label.Callback;

        end % get.Callback

        function set.Callback( obj, value )

            obj.Label.Callback = value;

        end % set.Callback

        function value = get.DeleteFcn( obj )

            value = obj.Label.DeleteFcn;

        end % get.DeleteFcn

        function set.DeleteFcn( obj, value )

            obj.Label.DeleteFcn = value;

        end % set.DeleteFcn

        function value = get.Enable( obj )

            value = obj.Label.Enable;

        end % get.Enable

        function set.Enable( obj, value )

            obj.Label.Enable = value;

        end % set.Enable

        function value = get.Extent( obj )

            % Get nominal extent
            c = obj.Label;
            value = c.Extent;

            % For JavaScript graphics, the Extent property is unreliable
            % for large font sizes, so getting the Extent of equivalent
            % Java graphics is more accurate
            f = ancestor( c, 'figure' );
            if ~isempty( f ) && value(4) > 40 && verLessThan( 'MATLAB', '25.1' ) && ...
                    isprop( f, 'JavaFrame_I' ) && isempty( f.JavaFrame_I ) %#ok<VERLESSMATLAB>
                df = figure( 'Visible', 'off' ); % dummy *Java* figure
                dc = copyobj( c, df ); % dummy control
                value(4) = dc.Extent(4); % use Java height
                delete( df ) % clean up
            end

        end % get.Extent

        function value = get.FontAngle( obj )

            value = obj.Label.FontAngle;

        end % get.FontAngle

        function set.FontAngle( obj, value )

            % Set
            obj.Label.FontAngle = value;

            % Mark as dirty
            obj.setDirty()

        end % set.FontAngle

        function value = get.FontName( obj )

            value = obj.Label.FontName;

        end % get.FontName

        function set.FontName( obj, value )

            % Set
            obj.Label.FontName = value;

            % Mark as dirty
            obj.setDirty()

        end % set.FontName

        function value = get.FontSize( obj )

            value = obj.Label.FontSize;

        end % get.FontSize

        function set.FontSize( obj, value )

            % Set
            obj.Label.FontSize = value;

            % Mark as dirty
            obj.setDirty()

        end % set.FontSize

        function value = get.FontUnits( obj )

            value = obj.Label.FontUnits;

        end % get.FontUnits

        function set.FontUnits( obj, value )

            obj.Label.FontUnits = value;

        end % set.FontUnits

        function value = get.FontWeight( obj )

            value = obj.Label.FontWeight;

        end % get.FontWeight

        function set.FontWeight( obj, value )

            % Set
            obj.Label.FontWeight = value;

            % Mark as dirty
            obj.setDirty()

        end % set.FontWeight

        function value = get.ForegroundColor( obj )

            value = obj.Label.ForegroundColor;

        end % get.ForegroundColor

        function set.ForegroundColor( obj, value )

            obj.Label.ForegroundColor = value;

        end % set.ForegroundColor

        function value = get.HandleVisibility( obj )

            value = obj.Container.HandleVisibility;

        end % get.HandleVisibility

        function set.HandleVisibility( obj, value )

            obj.Container.HandleVisibility = value;

        end % set.HandleVisibility

        function value = get.HorizontalAlignment( obj )

            value = obj.Label.HorizontalAlignment;

        end % get.HorizontalAlignment

        function set.HorizontalAlignment( obj, value )

            % Set
            obj.Label.HorizontalAlignment = value;

            % Mark as dirty
            obj.setDirty()

        end % set.HorizontalAlignment

        function value = get.Parent( obj )

            value = obj.Container.Parent;

        end % get.Parent

        function set.Parent( obj, value )

            obj.Container.Parent = value;

        end % set.Parent

        function value = get.Position( obj )

            value = obj.Container.Position;

        end % get.Position

        function set.Position( obj, value )

            obj.Container.Position = value;

        end % set.Position

        function value = get.String( obj )

            value = obj.Label.String;

        end % get.String

        function set.String( obj, value )

            % Set
            obj.Label.String = value;

            % Mark as dirty
            obj.setDirty()

        end % set.String

        function value = get.Tag( obj )

            value = obj.Label.Tag;

        end % get.Tag

        function set.Tag( obj, value )

            obj.Label.Tag = value;

        end % set.Tag

        function value = get.TooltipString( obj )

            value = obj.Label.TooltipString;

        end % get.TooltipString

        function set.TooltipString( obj, value )

            obj.Label.TooltipString = value;

        end % set.TooltipString

        function value = get.Type( obj )

            value = obj.Label.Type;

        end % get.Type

        function value = get.UIContextMenu( obj )

            value = obj.Label.UIContextMenu;

        end % get.UIContextMenu

        function set.UIContextMenu( obj, value )

            obj.Label.UIContextMenu = value;

        end % set.UIContextMenu

        function value = get.Units( obj )

            value = obj.Container.Units;

        end % get.Units

        function set.Units( obj, value )

            obj.Container.Units = value;

        end % set.Units

        function value = get.UserData( obj )

            value = obj.Label.UserData;

        end % get.UserData

        function set.UserData( obj, value )

            obj.Label.UserData = value;

        end % set.UserData

        function value = get.VerticalAlignment( obj )

            value = obj.VerticalAlignment_;

        end % get.VerticalAlignment

        function set.VerticalAlignment( obj, value )

            % Check
            assert( any( strcmp( value, {'top','middle','bottom'} ) ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''VerticalAlignment'' must be ''top'', ''middle'' or ''bottom''.' )

            % Set
            obj.VerticalAlignment_ = char( value );

            % Mark as dirty
            obj.setDirty()

        end % set.VerticalAlignment

        function value = get.Visible( obj )

            value = obj.Container.Visible;

        end % get.Visible

        function set.Visible( obj, value )

            obj.Container.Visible = value;

        end % set.Visible

    end % accessors

    methods( Access = private )

        function onResized( obj, ~, ~ )
            %onResized  Event handler

            % Rooted, so redraw
            obj.redraw()

        end % onResized

        function onFigureChanged( obj, ~, eventData )

            % If rooted, redraw
            if isempty( eventData.OldFigure ) && ...
                    ~isempty( eventData.NewFigure ) && obj.Dirty
                obj.redraw()
            end

        end % onFigureChanged

    end % event handlers

    methods( Access = private )

        function setDirty( obj )
            %setDirty  Mark as dirty
            %
            %  t.setDirty() marks the text control t as dirty.  If the text
            %  control is rooted then it is redrawn immediately.  If not
            %  then the redraw is queued for when it is next rooted.

            if isempty( obj.FigureObserver.Figure )
                obj.Dirty = true; % set flag
            else
                obj.Dirty = false; % unset flag
                obj.redraw() % redraw
            end

        end % setDirty

        function redraw( obj )
            %redraw  Redraw
            %
            %  t.redraw() redraws the text control t.  Note that this
            %  requires the text control to be rooted.  Methods should
            %  request redraws using setDirty, rather than calling redraw
            %  directly.

            c = obj.Container;
            b = obj.Label;
            bo = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', c ); % bounds
            e = obj.Extent;
            switch b.HorizontalAlignment
                case 'left'
                    x = 1;
                case 'center'
                    x = 1 + bo(3)/2 - e(3)/2;
                case 'right'
                    x = 1 + bo(3) - e(3);
            end
            w = e(3);
            switch obj.VerticalAlignment_
                case 'top'
                    y = 1 + bo(4) - e(4);
                case 'middle'
                    y = 1 + bo(4)/2 - e(4)/2;
                case 'bottom'
                    y = 1;
            end
            h = e(4);
            b.Position = [x y w h];

        end % redraw

    end % helpers

end % classdef