classdef ( Hidden ) Divider < matlab.mixin.SetGet
    %uix.Divider  Draggable divider
    %
    %  d = uix.Divider() creates a divider.
    %
    %  d = uix.Divider(p1,v1,p2,v2,...) creates a divider and sets
    %  specified property p1 to value v1, etc.

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( Dependent )
        Parent % parent
        Units % units [inches|centimeters|characters|normalized|points|pixels]
        Position % position
        Visible % visible [on|off]
        Color % color [RGB]
    end

    properties( Access = ?matlab.unittest.TestCase )
        Control % graphics
    end

    methods

        function obj = Divider( varargin )
            %uix.Divider  Draggable divider
            %
            %  d = uix.Divider() creates a divider.
            %
            %  d = uix.Divider(p1,v1,p2,v2,...) creates a divider and sets
            %  specified property p1 to value v1, etc.

            % Create control
            control = matlab.ui.container.internal.UIContainer( ...
                'Units', get( 0, 'DefaultUicontrolUnits' ), ...
                'Position', get( 0, 'DefaultUicontrolPosition' ), ...
                'Internal', true, 'DeleteFcn', @obj.onDeleted,...
                'Tag', 'uix.Divider' );

            % Store control
            obj.Control = control;

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

            control = obj.Control;
            if isgraphics( control ) && strcmp( control.BeingDeleted, 'off' )
                delete( control )
            end

        end % destructor

    end % structors

    methods

        function value = get.Parent( obj )

            value = obj.Control.Parent;

        end % get.Parent

        function set.Parent( obj, value )

            obj.Control.Parent = value;

        end % set.Parent

        function value = get.Units( obj )

            value = obj.Control.Units;

        end % get.Units

        function set.Units( obj, value )

            obj.Control.Units = value;

        end % set.Units

        function value = get.Position( obj )

            value = obj.Control.Position;

        end % get.Position

        function set.Position( obj, value )

            obj.Control.Position = value;

        end % set.Position

        function value = get.Visible( obj )

            value = obj.Control.Visible;

        end % get.Visible

        function set.Visible( obj, value )

            obj.Control.Visible = value;

        end % set.Visible

        function value = get.Color( obj )

            value = obj.Control.BackgroundColor;

        end % get.BackgroundColor

        function set.Color( obj, value )

            obj.Control.BackgroundColor = value;

        end % set.BackgroundColor

    end % accessors

    methods

        function tf = isMouseOver( obj, eventData )
            %isMouseOver  Test for mouse over
            %
            %  tf = d.isMouseOver(wmd) tests whether the WindowMouseData
            %  wmd is consistent with the mouse pointer being over the
            %  divider d.
            %
            %  This method returns false for dividers that are being
            %  deleted.

            tf = isvalid( obj ); % initialize
            for ii = 1:numel( obj )
                tf(ii) = tf(ii) && ~isempty( eventData.HitObject ) && ...
                    obj(ii).Control == eventData.HitObject;
            end

        end % isMouseOver

    end % methods

    methods( Access = private )

        function onDeleted( obj, ~, ~ )
            %onDeleted  Event handler

            % Call destructor
            obj.delete()

        end % onDeleted

    end % event handlers

end % classdef