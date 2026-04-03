classdef ScrollingPanel < uix.Container & uix.mixin.Container
    %uix.ScrollingPanel  Scrolling panel
    %
    %  p = uix.ScrollingPanel(p1,v1,p2,v2,...) constructs a scrolling panel
    %  and sets parameter p1 to value v1, etc.
    %
    %  A scrolling panel is a standard container (uicontainer) that shows
    %  one its contents and hides the others.
    %
    %  See also: uix.Panel, uix.BoxPanel, uix.TabPanel, uicontainer

    %  Copyright 2009-2025 The MathWorks, Inc.

    properties( Access = public, Dependent, AbortSet )
        Height % height of contents, in pixels and/or weights
        MinimumHeight % minimum height of contents, in pixels
        Width % width of contents, in pixels and/or weights
        MinimumWidth % minimum width of contents, in pixels
        VerticalStep % vertical slider step, in pixels
        VerticalOffset % vertical offset of contents, in pixels
        HorizontalStep % horizontal slider step, in pixels
        HorizontalOffset % horizontal offset of contents, in pixels
        MouseWheelEnabled % mouse wheel scrolling enabled [on|off]
    end

    properties( Access = private )
        Height_ = -1 % backing for Height
        MinimumHeight_ = 1 % backing for MinimumHeight
        Width_ = -1 % backing for Width
        MinimumWidth_ = 1 % backing for MinimumWidth
        VerticalSlider % slider
        VerticalStep_ = 10 % backing for VerticalStep
        HorizontalSlider % slider
        HorizontalStep_ = 10 % backing for HorizontalStep
        BlankingPlate % blanking plate
        MouseWheelListener % mouse listener
        MouseWheelEnabled_ = 'on' % backing for MouseWheelEnabled
        ScrollingListener % slider listener
        ScrolledListener % slider listener
        Scrolling_ = 'off' % scrolling flag
    end

    properties( Access = public, Hidden )
        Continuous = 'on' % continuous scrolling
    end

    properties( Access = public, Dependent, AbortSet, Hidden )
        Heights % transitioned to Height
        MinimumHeights % transitioned to MinimumHeight
        Widths % transitioned to Width
        MinimumWidths % transitioned to MinimumWidth
        VerticalSteps % transitioned to VerticalStep
        VerticalOffsets % transitioned to VerticalOffset
        HorizontalSteps % transitioned to HorizontalStep
        HorizontalOffsets % transitioned to HorizontalOffset
        Selection % deprecated
    end % deprecated properties

    properties( Access = ?matlab.unittest.TestCase )
        SliderSize = 20 % slider size, in pixels
    end

    events( NotifyAccess = private )
        Scrolled
    end

    methods

        function obj = ScrollingPanel( varargin )
            %uix.ScrollingPanel  Scrolling panel constructor
            %
            %  p = uix.ScrollingPanel() constructs a scrolling panel.
            %
            %  p = uix.ScrollingPanel(p1,v1,p2,v2,...) sets parameter p1 to
            %  value v1, etc.

            % Create sliders
            vSlider = matlab.ui.control.UIControl( ...
                'Internal', true, 'Parent', obj, ...
                'Units', 'pixels', 'Style', 'slider', ...
                'BackgroundColor', obj.BackgroundColor );
            hSlider = matlab.ui.control.UIControl( ...
                'Internal', true, 'Parent', obj, ...
                'Units', 'pixels', 'Style', 'slider', ...
                'BackgroundColor', obj.BackgroundColor );
            plate = matlab.ui.control.UIControl( ...
                'Internal', true, 'Parent', obj, ...
                'Units', 'pixels', 'Style', 'text', 'Enable', 'inactive', ...
                'BackgroundColor', obj.BackgroundColor );

            % Store properties
            obj.VerticalSlider = vSlider;
            obj.HorizontalSlider = hSlider;
            obj.BlankingPlate = plate;

            % Initialize decorations
            obj.updateBackgroundColor()

            % Create listeners
            addlistener( obj, 'BackgroundColor', 'PostSet', ...
                @obj.onBackgroundColorChanged );
            scrollingListener = event.listener( [vSlider; hSlider], ...
                'ContinuousValueChange', @obj.onSliderScrolling );
            scrolledListener = event.listener( [vSlider; hSlider], ...
                'Action', @obj.onSliderScrolled );

            % Store listeners
            obj.ScrollingListener = scrollingListener;
            obj.ScrolledListener = scrolledListener;

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

        function value = get.Height( obj )

            value = obj.Height_;

        end % get.Height

        function set.Height( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''Height'' must be numeric, scalar, real and finite.' )

            % Set
            obj.Height_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.Height

        function value = get.MinimumHeight( obj )

            value = obj.MinimumHeight_;

        end % get.MinimumHeight

        function set.MinimumHeight( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ) && ...
                value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''MinimumHeight'' must be numeric, scalar, real, finite and positive.' )

            % Set
            obj.MinimumHeight_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.MinimumHeight

        function value = get.Width( obj )

            value = obj.Width_;

        end % get.Width

        function set.Width( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''Width'' must be numeric, scalar, real and finite.' )

            % Set
            obj.Width_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.Width

        function value = get.MinimumWidth( obj )

            value = obj.MinimumWidth_;

        end % get.MinimumWidth

        function set.MinimumWidth( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ) && ...
                value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''MinimumWidth'' must be numeric, scalar, real, finite and positive.' )

            % Set
            obj.MinimumWidth_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.MinimumWidth

        function value = get.VerticalOffset( obj )

            value = -obj.VerticalSlider.Value;

        end % get.VerticalOffset

        function set.VerticalOffset( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''VerticalOffset'' must be numeric, scalar, real and finite.' )

            % Set
            obj.VerticalSlider.Value = double( -value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.VerticalOffset

        function value = get.VerticalStep( obj )

            value = obj.VerticalStep_;

        end % get.VerticalStep

        function set.VerticalStep( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ) && ...
                value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''VerticalStep'' must be numeric, scalar, real, finite and positive.' )

            % Set
            obj.VerticalStep_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.VerticalStep

        function value = get.HorizontalOffset( obj )

            value = obj.HorizontalSlider.Value;

        end % get.HorizontalOffset

        function set.HorizontalOffset( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ), ...
                'uix:InvalidPropertyValue', ...
                'Property ''HorizontalOffset'' must be numeric, scalar, real and finite.' )

            % Set
            obj.HorizontalSlider.Value = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.HorizontalOffset

        function value = get.HorizontalStep( obj )

            value = obj.HorizontalStep_;

        end % get.HorizontalStep

        function set.HorizontalStep( obj, value )

            % Check
            assert( isnumeric( value ) && isscalar( value ) && ...
                isreal( value ) && ~isnan( value ) && ~isinf( value ) && ...
                value > 0, ...
                'uix:InvalidPropertyValue', ...
                'Property ''HorizontalStep'' must be numeric, scalar, real, finite and positive.' )

            % Set
            obj.HorizontalStep_ = double( value );

            % Mark as dirty
            obj.Dirty = true;

        end % set.HorizontalStep

        function value = get.MouseWheelEnabled( obj )

            value = obj.MouseWheelEnabled_;

        end % get.MouseWheelEnabled

        function set.MouseWheelEnabled( obj, value )

            % Check
            try
                value = char( value );
                assert( ismember( value, {'on','off'} ) )
            catch
                error( 'uix:InvalidArgument', ...
                    'Property ''MouseWheelEnabled'' must be ''on'' or ''off''.' )
            end

            % Set
            obj.MouseWheelEnabled_ = value;
            listener = obj.MouseWheelListener;
            if ~isempty( listener )
                listener.Enabled = strcmp( value, 'on' );
            end

        end % set.MouseWheelEnabled

        function set.Continuous( obj, value )

            % Check
            try
                value = char( value );
                assert( ismember( value, {'on','off'} ) )
            catch
                error( 'uix:InvalidArgument', ...
                    'Property ''Continuous'' must be ''on'' or ''off''.' )
            end

            % Set
            obj.Continuous = value;

        end % set.Continuous

    end % accessors

    methods

        function value = get.Heights( obj )

            value = repmat( obj.Height, size( obj.Contents_ ) );

        end % get.Heights

        function set.Heights( obj, value ) % moved to Height

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''Heights'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.Height = value(end); % top
            end

        end % set.Heights

        function value = get.MinimumHeights( obj )

            value = repmat( obj.MinimumHeight, size( obj.Contents_ ) );

        end % get.MinimumHeights

        function set.MinimumHeights( obj, value ) % moved to MinimumHeight

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''MinimumHeights'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.MinimumHeight = value(end); % top
            end

        end % set.MinimumHeights

        function value = get.Widths( obj )

            value = repmat( obj.Width, size( obj.Contents_ ) );

        end % get.Widths

        function set.Widths( obj, value ) % moved to Width

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''Widths'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.Width = value(end); % top
            end

        end % set.Widths

        function value = get.MinimumWidths( obj )

            value = repmat( obj.MinimumWidth, size( obj.Contents_ ) );

        end % get.MinimumWidths

        function set.MinimumWidths( obj, value ) % moved to MinimumWidth

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''MinimumWidths'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.MinimumWidth = value(end); % top
            end

        end % set.MinimumWidths

        function value = get.VerticalSteps( obj )

            value = repmat( obj.VerticalStep, size( obj.Contents_ ) );

        end % get.VerticalSteps

        function set.VerticalSteps( obj, value ) % moved to VerticalStep

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''VerticalSteps'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.VerticalStep = value(end); % top
            end

        end % set.VerticalSteps

        function value = get.VerticalOffsets( obj )

            value = repmat( obj.VerticalOffset, size( obj.Contents_ ) );

        end % get.VerticalOffsets

        function set.VerticalOffsets( obj, value ) % moved to VerticalOffset

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''VerticalOffsets'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.VerticalOffset = value(end); % top
            end

        end % set.VerticalOffsets

        function value = get.HorizontalSteps( obj )

            value = repmat( obj.HorizontalStep, size( obj.Contents_ ) );

        end % get.HorizontalSteps

        function set.HorizontalSteps( obj, value ) % moved to HorizontalStep

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''HorizontalSteps'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.HorizontalStep = value(end); % top
            end

        end % set.HorizontalSteps

        function value = get.HorizontalOffsets( obj )

            value = repmat( obj.HorizontalOffset, size( obj.Contents_ ) );

        end % get.HorizontalOffsets

        function set.HorizontalOffsets( obj, value ) % moved to HorizontalOffset

            % Check
            assert( numel( value ) == numel( obj.Contents_ ), ...
                'uix:InvalidArgument', ...
                'Property ''HorizontalOffsets'' must be an array, one per child.' )

            % Set
            if ~isempty( value )
                obj.HorizontalOffset = value(end); % top
            end

        end % set.HorizontalOffsets

        function value = get.Selection( obj )

            value = numel( obj.Contents_ );

        end % get.Selection

        function set.Selection( ~, ~ ) % removed

        end % set.Selection

    end % deprecated accessors

    methods( Access = protected )

        function redraw( obj )
            %redraw  Redraw

            % Retrieve width, height and padding
            contentsWidth = obj.Width_;
            minimumWidth = obj.MinimumWidth_;
            contentsHeight = obj.Height_;
            minimumHeight = obj.MinimumHeight_;
            padding = obj.Padding_;

            % Retrieve decorations
            vSlider = obj.VerticalSlider;
            hSlider = obj.HorizontalSlider;
            plate = obj.BlankingPlate;

            % Compute dimensions
            panelBounds = hgconvertunits( ancestor( obj, 'figure' ), ...
                [0 0 1 1], 'normalized', 'pixels', obj );
            panelWidth = panelBounds(3);
            panelHeight = panelBounds(4);
            sliderSize = obj.SliderSize; % slider size
            vSliderWidth = sliderSize * ...
                (contentsHeight + 2*padding > panelHeight | ...
                minimumHeight + 2*padding > panelHeight); % first pass
            hSliderHeight = sliderSize * ...
                (contentsWidth + 2*padding > panelWidth - vSliderWidth | ...
                minimumWidth + 2*padding > panelWidth - vSliderWidth);
            vSliderWidth = sliderSize * ...
                (contentsHeight + 2*padding > panelHeight - hSliderHeight | ...
                minimumHeight + 2*padding > panelHeight - hSliderHeight); % second pass
            vSliderWidth = min( vSliderWidth, panelWidth ); % limit
            hSliderHeight = min( hSliderHeight, panelHeight ); % limit
            vSliderHeight = panelHeight - hSliderHeight;
            hSliderWidth = panelWidth - vSliderWidth;
            widths = uix.calcPixelSizes( panelWidth, ...
                [contentsWidth;vSliderWidth], ...
                [minimumWidth;vSliderWidth], padding, 0 );
            contentsWidth = widths(1);
            heights = uix.calcPixelSizes( panelHeight, ...
                [contentsHeight;hSliderHeight], ...
                [minimumHeight;hSliderHeight], padding, 0 );
            contentsHeight = heights(1);

            % Compute positions
            contentsPosition = [1 1 0 0] + ...
                [0 0 contentsWidth contentsHeight] + ...
                hSliderHeight * [0 1 0 0] + ...
                padding * [1 1 0 0];
            vSliderPosition = [1 1 0 0] + ...
                [hSliderWidth hSliderHeight vSliderWidth vSliderHeight];
            hSliderPosition = [1 1 0 0] + ...
                [0 0 hSliderWidth hSliderHeight];
            platePosition = [1 1 0 0] + ...
                [hSliderWidth 0 vSliderWidth hSliderHeight];

            % Compute vertical slider properties
            if vSliderWidth == 0 || vSliderHeight == 0 || vSliderHeight <= vSliderWidth
                % Slider is invisible or incorrectly oriented
                vSliderEnable = 'off';
                vSliderMin = -1; % bottom
                vSliderMax = 0; % top
                vSliderValue = vSliderMax; % top
                vSliderStep = vSlider.SliderStep;
            else
                % Compute properties
                vSliderEnable = 'on';
                vSliderMin = (panelHeight - hSliderHeight) - ...
                    (contentsHeight + 2*padding); % bottom
                vSliderMax = 0; % top
                vSliderValue = vSlider.Value; % actual
                vSliderValue = max( vSliderValue, vSliderMin ); % limit
                vSliderValue = min( vSliderValue, vSliderMax ); % limit
                vStep = obj.VerticalStep_;
                vSliderStep(1) = vStep / (vSliderMax - vSliderMin); % minor
                vSliderStep(1) = min( vSliderStep(1), 1 ); % limit minor
                vSliderStep(2) = (panelHeight - hSliderHeight) / ...
                    (vSliderMax - vSliderMin); % major
                vSliderStep(1) = min( vSliderStep(1), vSliderStep(2) ); % limit minor
                contentsPosition(2) = contentsPosition(2) - vSliderValue ...
                    - vSliderMax + vSliderMin;
            end

            % Compute horizontal slider properties
            if hSliderHeight == 0 || hSliderWidth == 0 || hSliderWidth <= hSliderHeight
                % Slider is invisible or incorrectly oriented
                hSliderEnable = 'off';
                hSliderMin = 0; % left
                hSliderMax = 1; % right
                hSliderValue = hSliderMin; % left
                hSliderStep = hSlider.SliderStep;
            else
                % Compute properties
                hSliderEnable = 'on';
                hSliderMin = 0; % left
                hSliderMax = (contentsWidth + 2*padding) - ...
                    (panelWidth - vSliderWidth); % right
                hSliderValue = hSlider.Value; % actual
                hSliderValue = max( hSliderValue, hSliderMin ); % limit
                hSliderValue = min( hSliderValue, hSliderMax ); % limit
                hStep = obj.HorizontalStep_;
                hSliderStep(1) = hStep / (hSliderMax - hSliderMin); % minor
                hSliderStep(1) = min( hSliderStep(1), 1 ); % limit minor
                hSliderStep(2) = (panelWidth - vSliderWidth) / ...
                    (hSliderMax - hSliderMin); % major
                hSliderStep(1) = min( hSliderStep(1), hSliderStep(2) ); % limit minor
                contentsPosition(1) = contentsPosition(1) - hSliderValue;
            end

            % Set scrollbar properties. Setting properties interrupts
            % continuous scrolling, so only proceed if the component is not
            % being scrolled.
            if strcmp( obj.Scrolling_, 'off' )
                set( vSlider, 'Style', 'slider', ...
                    'Enable', vSliderEnable, ...
                    'Position', vSliderPosition, ...
                    'Min', vSliderMin, 'Max', vSliderMax, ...
                    'Value', vSliderValue, 'SliderStep', vSliderStep )
                set( hSlider, 'Style', 'slider', ...
                    'Enable', hSliderEnable, ...
                    'Position', hSliderPosition, ...
                    'Min', hSliderMin, 'Max', hSliderMax, ...
                    'Value', hSliderValue, 'SliderStep', hSliderStep )
            end % if

            % Set contents and blanking plate positions
            contents = obj.Contents_;
            for ii = 1:numel( contents )
                uix.setPosition( contents(ii), contentsPosition, 'pixels' )
            end
            plate.Position = platePosition;

        end % redraw

        function addChild( obj, child )

            % Call superclass method
            addChild@uix.mixin.Container( obj, child )

            % Bring decorations to front
            obj.HorizontalSlider.Parent = [];
            obj.VerticalSlider.Parent = [];
            obj.BlankingPlate.Parent = [];
            obj.HorizontalSlider.Parent = obj;
            obj.VerticalSlider.Parent = obj;
            obj.BlankingPlate.Parent = obj;

        end % addChild

        function reparent( obj, ~, newFigure )
            %reparent  Reparent container
            %
            %  c.reparent(a,b) reparents the container c from the figure a
            %  to the figure b.

            if isempty( newFigure )
                obj.MouseWheelListener = [];
            else
                listener = event.listener( newFigure, ...
                    'WindowScrollWheel', @obj.onMouseScrolled );
                listener.Enabled = strcmp( obj.MouseWheelEnabled_, 'on' );
                obj.MouseWheelListener = listener;
            end

        end % reparent

        function retheme( obj )
            %retheme  Retheme container

            obj.updateBackgroundColor()

        end % retheme

    end % template methods

    methods( Access = ?matlab.unittest.TestCase )

        function onSliderScrolling( obj, ~, ~ )
            %onSliderScrolling  Event handler

            if strcmp( obj.Continuous, 'on' )

                try

                    % Mark as dirty
                    obj.Scrolling_ = 'on'; % set flag
                    obj.Dirty = true;
                    obj.Scrolling_ = 'off'; % unset flag

                catch e

                    obj.Scrolling_ = 'off'; % clean up
                    rethrow( e )

                end

                % Raise event
                notify( obj, 'Scrolled' )

            end

        end % onSliderScrolling

        function onSliderScrolled( obj, ~, ~ )
            %onSliderScrolled  Event handler

            % Mark as dirty
            obj.Dirty = true;

            % Raise event
            notify( obj, 'Scrolled' )

        end % onSliderScrolled

        function onMouseScrolled( obj, ~, eventData )
            %onMouseScrolled  Event handler

            % Get pointer position and panel bounds
            pp = getpixelposition( obj, true );
            f = ancestor( obj, 'figure' );
            cpu = f.CurrentPoint; % figure Units
            cpwhu = [cpu 0 0]; % [x y] to [x y w h] for hgconvertunits
            cpwh = hgconvertunits( f, cpwhu, f.Units, 'pixels', obj ); % pixels
            cp = cpwh(1:2); % [x y w h] to [x y]

            % Check that pointer is over panel
            if cp(1) < pp(1) || cp(1) > pp(1) + pp(3) || ...
                    cp(2) < pp(2) || cp(2) > pp(2) + pp(4), return, end

            % Scroll
            if strcmp( obj.VerticalSlider.Enable, 'on' ) % scroll vertically
                delta = eventData.VerticalScrollCount * ...
                    eventData.VerticalScrollAmount * obj.VerticalStep;
                obj.VerticalOffset = obj.VerticalOffset + delta;
            elseif strcmp( obj.HorizontalSlider.Enable, 'on' ) % scroll horizontally
                delta = eventData.VerticalScrollCount * ...
                    eventData.VerticalScrollAmount * obj.HorizontalStep;
                obj.HorizontalOffset = obj.HorizontalOffset + delta;
            end

            % Raise event
            notify( obj, 'Scrolled' )

        end % onMouseScrolled

        function onBackgroundColorChanged( obj, ~, ~ )
            %onBackgroundColorChanged  Handler for BackgroundColor changes

            obj.updateBackgroundColor()

        end % onBackgroundColorChanged

    end % event handlers

    methods( Access = private )

        function updateBackgroundColor( obj )
            %updateBackgroundColor  Update foreground color

            backgroundColor = obj.BackgroundColor;
            obj.HorizontalSlider.BackgroundColor = backgroundColor;
            obj.VerticalSlider.BackgroundColor = backgroundColor;
            obj.BlankingPlate.BackgroundColor = backgroundColor;

        end % updateBackgroundColor

    end % helper methods

end % classdef