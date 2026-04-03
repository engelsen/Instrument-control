classdef Panel < matlab.ui.container.Panel & uix.mixin.Container
    %uix.Panel  Standard panel
    %
    %  b = uix.Panel(p1,v1,p2,v2,...) constructs a standard panel and sets
    %  parameter p1 to value v1, etc.
    %
    %  See also: uix.CardPanel, uix.BoxPanel, uipanel

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( Dependent, Hidden )
        Selection
    end % deprecated properties

    methods

        function obj = Panel( varargin )
            %uix.Panel  Standard panel constructor
            %
            %  p = uix.Panel() constructs a standard panel.
            %
            %  p = uix.Panel(p1,v1,p2,v2,...) sets parameter p1 to value
            %  v1, etc.

            % Set properties
            try
                uix.set( obj, varargin{:} )
            catch e
                delete( obj )
                e.throwAsCaller()
            end

            % Disable auto resize
            if isprop( obj, 'AutoResizeChildren' )
                obj.AutoResizeChildren = 'off';
            end

        end % constructor

    end % structors

    methods

        function value = get.Selection( obj )

            value = numel( obj.Contents_ );

        end % get.Selection

        function set.Selection( ~, ~ ) % removed

        end % set.Selection

    end % deprecated accessors

    methods( Access = protected )

        function redraw( obj )

            % Compute positions
            bounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            padding = obj.Padding_;
            xSizes = uix.calcPixelSizes( bounds(3), -1, 1, padding, 0 );
            ySizes = uix.calcPixelSizes( bounds(4), -1, 1, padding, 0 );
            position = [padding+1 padding+1 xSizes ySizes];

            % Redraw contents
            contents = obj.Contents_;
            for ii = 1:numel( contents )
                uix.setPosition( contents(ii), position, 'pixels' )
            end

        end % redraw

    end % template methods

    methods( Access = protected, Static )

        function map = getThemeMap()
            %getThemeMap  Map class properties to theme attributes

            map = struct();
            map.BackgroundColor = '--mw-backgroundColor-primary';
            map.HighlightColor = '--mw-borderColor-primary';
            map.ForegroundColor = '--mw-color-primary';

        end % getThemeMap

    end % protected static methods

end % classdef