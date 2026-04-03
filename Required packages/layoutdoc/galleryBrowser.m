function varargout = galleryBrowser()
%galleryBrowser: an example of using layouts to build a user interface
%
%   galleryBrowser() opens a simple app that allows several of MATLAB's
%   built-in examples to be viewed. It aims to demonstrate how multiple
%   layouts can be used to create a good-looking user interface that
%   retains the correct proportions when resized. It also shows how to
%   connect callbacks to interpret user interaction.

%  Copyright 2009-2024 The MathWorks, Inc.

% Data is shared between all child functions by declaring the variables
% here (they become global to the function). We keep things tidy by putting
% all app components in one structure and all data in another. As the app
% grows, we might consider making these objects rather than structures.
data = createData();
app = createInterface( data.ExampleNames );

% Now update the app with the current data
updateInterface()
redrawExample()

% Return the figure if an output is requested.
nargoutchk( 0, 1 )
if nargout == 1
    varargout{1} = app.Figure;
end % if

    function data = createData()

        % Create the shared data-structure for this application
        exampleList = {
            'Complex surface'            'cplxdemo'
            'Cruller'                    'cruller'
            'Earth'                      'earthmap'
            'Four linked tori'           'tori4'
            'Klein bottle'               'xpklein'
            'Klein bottle (1)'           'klein1'
            'Knot'                       'knot'
            'Logo'                       'logo'
            'Spherical Surface Harmonic' 'spharm2'
            'Werner Boy''s Surface'      'wernerboy'
            };
        selectedExample = 8;
        data = struct( ...
            'ExampleNames', {exampleList(:,1)'}, ...
            'ExampleFunctions', {exampleList(:,2)'}, ...
            'SelectedExample', selectedExample );

    end % createData

    function app = createInterface( exampleList )

        % Create the user interface for the application and return a
        % structure of handles for global use.
        app = struct();

        % Create a figure and add some menus
        app.Figure = figure( ...
            'Name', 'Gallery Browser', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'none', ...
            'HandleVisibility', 'off' );

        % File menu
        app.FileMenu = uimenu( app.Figure, 'Label', 'File' );
        uimenu( app.FileMenu, 'Label', 'Exit', 'Callback', @onExit )

        % View menu
        app.ViewMenu = uimenu( app.Figure, 'Label', 'View' );
        for ii = 1 : numel( exampleList )
            uimenu( app.ViewMenu, 'Label', exampleList{ii}, ...
                'Callback', @onMenuSelection )
        end

        % Help menu
        helpMenu = uimenu( app.Figure, 'Label', 'Help' );
        uimenu( helpMenu, 'Label', 'GUI Layout Toolbox Documentation', ...
            'Callback', @onHelp )

        % Arrange the main interface
        mainLayout = uix.HBoxFlex( 'Parent', app.Figure, 'Spacing', 3 );

        % Create the panels
        controlPanel = uix.BoxPanel( ...
            'Parent', mainLayout, ...
            'Title', 'Select an example' );
        app.ViewPanel = uix.BoxPanel( ...
            'Parent', mainLayout, ...
            'Title', 'Viewing: ???', ...
            'HelpFcn', @onSourceCodeRequested );
        app.ViewContainer = uicontainer( ...
            'Parent', app.ViewPanel );

        % Adjust the main layout
        mainLayout.Widths = [-1, -2];

        % Create the controls
        controlLayout = uix.VBox( 'Parent', controlPanel, ...
            'Padding', 3, 'Spacing', 3 );
        app.ListBox = uicontrol( 'Parent', controlLayout, ...
            'Style', 'listbox', ...            
            'String', exampleList(:), ...
            'Value', 1, ...
            'Callback', @onListSelection );
        app.SourceCodeButton = uicontrol( 'Style', 'pushbutton', ...
            'Parent', controlLayout, ...
            'String', 'Source Code for <example>', ...
            'Callback', @onSourceCodeRequested );

        % Make the list fill the space
        controlLayout.Heights = [-1, 28];

        % Create the view        
        app.ViewAxes = axes( 'Parent', app.ViewContainer );

    end % createInterface

    function updateInterface()
        % Update various parts of the interface in response to the example
        % being changed.

        % Update the list and menu to show the current example
        app.ListBox.Value = data.SelectedExample;

        % Update the source code button label
        exampleFunction = data.ExampleFunctions{data.SelectedExample};
        app.SourceCodeButton.String = ...
            ['Source code for ', exampleFunction];

        % Update the view panel title
        exampleName = data.ExampleNames{data.SelectedExample};
        app.ViewPanel.Title = sprintf( 'Viewing: %s', exampleName );

        % Untick all menus
        menus = get( app.ViewMenu, 'Children' );
        set( menus, 'Checked', 'off' )

        % Use the name to work out which menu item should be ticked
        whichMenu = strcmpi( exampleName, get( menus, 'Label' ) );
        menus(whichMenu).Checked = 'on';

    end % updateInterface

    function redrawExample()
        % Draw a example into the axes provided

        % We first clear the existing axes ready to build a new one
        if ishandle( app.ViewAxes )
            delete( app.ViewAxes );
        end

        % Some examples create their own figure. Others don't.
        fcnName = data.ExampleFunctions{data.SelectedExample};
        switch upper( fcnName )
            case 'LOGO'
                % These examples open their own windows
                evalin( 'base', fcnName );
                app.ViewAxes = gca();
                fig = gcf();
                fig.Visible = 'off';
            otherwise
                % These examples need a figure
                fig = figure( 'Visible', 'off' );
                evalin( 'base', fcnName );
                app.ViewAxes = gca();
        end

        % Now copy the axes from the example into our window and restore its
        % state.
        cmap = colormap( app.ViewAxes );
        app.ViewAxes.Parent = app.ViewContainer;
        colormap( app.ViewAxes, cmap )
        rotate3d( app.ViewAxes, 'on' )

        % Get rid of the example figure
        close( fig )

    end % redrawExample

    function onListSelection( src, ~ )

        % User selected an example from the list - update data and refresh
        data.SelectedExample = get( src, 'Value' );
        updateInterface()
        redrawExample()

    end % onListSelection

    function onMenuSelection( src, ~ )

        % User selected a example from the menu - work out which one
        exampleName = get( src, 'Label' );
        data.SelectedExample = find( strcmpi( exampleName, ...
            data.ExampleNames ), 1, 'first' );
        updateInterface()
        redrawExample()

    end % onMenuSelection

    function onHelp( ~, ~ )

        % Open the toolbox documentation
        doc( 'GUI Layout Toolbox' )

    end % onHelp

    function onSourceCodeRequested( ~, ~ )

        % Open the source code for the selected example
        edit( data.ExampleFunctions{data.SelectedExample} )

    end % onSourceCodeRequested

    function onExit( ~, ~ )

        % User wants to exit from the application
        delete( app.Figure )

    end % onExit

end % galleryBrowser