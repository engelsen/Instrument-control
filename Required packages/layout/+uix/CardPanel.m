classdef CardPanel < uix.Container & uix.mixin.Container
    %uix.CardPanel  Card panel
    %
    %  b = uix.CardPanel(p1,v1,p2,v2,...) constructs a card panel and sets
    %  parameter p1 to value v1, etc.
    %
    %  A card panel is a standard container (uicontainer) that shows one
    %  its contents and hides the others.
    %
    %  See also: uix.Panel, uix.BoxPanel, uix.TabPanel, uicontainer

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( Access = public, Dependent, AbortSet )
        Selection % selection
    end

    properties( Access = private )
        Selection_ = 0 % backing for Selection
    end

    events( NotifyAccess = private )
        SelectionChanged % selection changed
    end

    methods

        function obj = CardPanel( varargin )
            %uix.CardPanel  Card panel constructor
            %
            %  p = uix.CardPanel() constructs a card panel.
            %
            %  p = uix.CardPanel(p1,v1,p2,v2,...) sets parameter p1 to
            %  value v1, etc.

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

        function value = get.Selection( obj )

            value = obj.Selection_;

        end % get.Selection

        function set.Selection( obj, newValue )

            % Check
            try
                validateattributes( newValue, {'numeric'}, ...
                    {'scalar','integer','positive'} )
                assert( newValue <= numel( obj.Contents_ ) ) % nb AbortSet
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''Selection'' must be between 1 and the number of contents.' )
            end

            % Set
            oldValue = obj.Selection_;
            obj.Selection_ = newValue;

            % Raise event
            notify( obj, 'SelectionChanged', ... )
                uix.SelectionChangedData( oldValue, newValue ) )

            % Show and hide
            contents = obj.Contents_;
            uix.setVisible( contents(oldValue), 'off' ) % hide old
            uix.setVisible( contents(newValue), 'on' ) % show new

            % Mark as dirty
            obj.Dirty = true;

        end % set.Selection

    end % accessors

    methods( Access = protected )

        function redraw( obj )
            %redraw  Redraw

            % Skip if no contents
            i = obj.Selection_;
            if i == 0, return, end

            % Compute positions
            b = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            pa = obj.Padding_;
            w = uix.calcPixelSizes( b(3), -1, 1, pa, 0 );
            h = uix.calcPixelSizes( b(4), -1, 1, pa, 0 );
            cp = [1+pa 1+pa w h];

            % Redraw contents
            uix.setPosition( obj.Contents_(i), cp, 'pixels' )

        end % redraw

        function addChild( obj, child )
            %addChild  Add child
            %
            %  c.addChild(d) adds the child d to the container c.

            % Capture old state
            oldContents = obj.Contents_;
            oldSelection = obj.Selection_;

            % Call superclass method
            addChild@uix.mixin.Container( obj, child )

            % Update selection
            obj.Selection_ = find( obj.Contents_ == child ); % added

            % Show and hide
            if oldSelection ~= 0
                uix.setVisible( oldContents(oldSelection), 'off' ) % hide old
            end
            if obj.G1136196 && strcmp( child.Visible, 'off' ) % bug
                on = @() eq( obj.Contents(obj.Selection), child );
                uix.setVisible( child, on, 0.02 ) % future show new
            else
                uix.setVisible( child, 'on' ) % show new
            end

            % Mark as dirty
            obj.Dirty = true;

        end % addChild

        function removeChild( obj, child )
            %removeChild  Remove child
            %
            %  c.removeChild(d) removes the child d from the container c.

            % Capture old state
            oldContents = obj.Contents_;
            oldSelection = obj.Selection_;

            % Call superclass method
            removeChild@uix.mixin.Container( obj, child )

            % Update selection
            newContents = obj.Contents_;
            if isempty( newContents ) % remove only child
                obj.Selection_ = 0; % none
            elseif oldContents(oldSelection) == child % remove selected child
                newSelection = min( oldSelection, numel( newContents ) ); % next or last
                obj.Selection_ = newSelection;
                uix.setVisible( newContents(newSelection), 'on' ) % show new
            else % remove other child, retain selection
                obj.Selection_ = find( newContents == oldContents(oldSelection) ); % same
            end

        end % removeChild

        function reorder( obj, indices )
            %reorder  Reorder contents
            %
            %  c.reorder(i) reorders the container contents using indices
            %  i, c.Contents = c.Contents(i).

            % Call superclass method
            reorder@uix.mixin.Container( obj, indices )

            % Update selection
            oldSelection = obj.Selection_;
            if oldSelection ~= 0
                obj.Selection_ = find( indices == oldSelection );
            end

        end % reorder

    end % template methods

end % classdef