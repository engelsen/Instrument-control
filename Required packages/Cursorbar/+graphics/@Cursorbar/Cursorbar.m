classdef Cursorbar < graphics.Graphics & matlab.mixin.SetGet
	% CURSORBAR  Creates a cursor line attached to an axes or lines.
	%
	% The Cursorbar can be dragged interactively across the axes. If
	% attached to a plot, the cursor points are updated as well. The
	% Cursorbar can be either horizontal or vertical.
	%
	% Cursorbar requires the new MATLAB graphics system that was
	% introduced in R2014b
	%
	% Usage:
	%    graphics.Cursorbar(hTarget)      - Creates a Cursorbar on a target
	%                                       Axes or Chart.
	%    graphics.Cursorbar(hTarget, ...) - Creates a Cursorbar on a target 
	%                                       Axes or Chart with additional
	%                                       property-value pairs.
	% Example:
	%    x  = linspace(0,20,101);
	%    y  = sin(x);
	%    %
	%    h  = plot(x,y);
	%    graphics.Cursorbar(h);
	%    
	% Cursorbar Constructor:
	%    Cursorbar               - Cursorbar constructor
	%
	% Cursorbar Properties:
	%    Annotation              - Legend icon display style
	%    BeingDeleted            - Deletion status of group
	%    BottomHandle            - Handle to the bottom (left) edge marker
	%    BottomMarker            - Top (right) edge marker shape
	%    BusyAction              - Callback queuing
	%    ButtonDownFcn           - Mouse-click callback
	%    Children                - Children of Cursorbar
	%    CreateFcn               - Creation callback
	%    CursorLineColor         - Cursor line's color
	%    CursorLineStyle         - Cursor line's style
	%    CursorLineWidth         - Cursor line's width
	%    CursorbarOrientation    - Permitted Cursorbar Orientation options
	%    CursorbarShowText       - Permitted Cursorbar ShowText options
	%    DataCursorHandle        - Handle to the Data Cursor
	%    DeleteFcn               - Deletion callback
	%    DisplayHandle           - Display text handle
	%    DisplayName             - Text used by the legend
	%    FigureCallbacks         - Additional Figure callbacks
	%    HandleVisibility        - Visibility of object handle {'on','off'}
	%    HitTest                 - Response to mouse clicks captured by
	%                              children
	%    Interruptible           - Callback interruption
	%    Location                - Location is a single value which is used
	%                              to set the Position, based on the
	%                              Orientation
	%    Orientation             - Orientation of Cursorbar
	%                              {'vertical','horizontal'}
	%    Parent                  - Parent of Cursorbar
	%    PermittedChartTargets   - Classes of permitted targets
	%    PickableParts           - Children that can capture mouse clicks
	%    Position                - Position is used to set the location of
	%                              main marker for the intersection
	%    Selected                - Selection state
	%    SelectionHighlight      - Display of selection handles when
	%                              selected
	%    ShowText                - Showing the Cursorbar Text {'on','off'}
	%    Tag                     - Tag to associate with the Cursorbar
	%    Target                  - Handle to the Target
	%    TargetIntersections     - How many intersections are plotted
	%                              {'multiple','single'}
	%    TargetMarkerEdgeColor   - Target's marker outline color
	%    TargetMarkerFaceColor   - Target's marker fill color
	%    TargetMarkerSize        - Target's marker size
	%    TargetMarkerStyle       - Target's marker style
	%    TextDescription         - Type of text description
	%                              {'short','long'}
	%    TopHandle               - Handle to the top (right) edge marker
	%    TopMarker               - Top (right) edge marker shape
	%    Type                    - Type of graphics object
	%    UIContextMenu           - Context menu
	%    UpdateFcn               - Update callback
	%    UserData                - Data to associate with the Cursorbar
	%                              object
	%    Visible                 - Visibility of Cursorbar {'on','off'}
	%
	% Cursorbar Methods:
	%    drawCrossbar            - Draws a linked perpendicular bar
	%    duplicate               - Duplicate the cursorbar to an identical
	%                              one
	%    getCursorInfo           - Get DataCursor info from Cursorbar
	%    getMarkerLocations      - Return x,y position of the Cursorbar's
	%                              intersection markers
	%    ishandle                - Checks on self if valid handle
	%    isTargetAxes            - Is the Target an axes
	%    isTargetChart           - Is the Target a permitted chart object
	%
	% Inherited <a href="matlab:help matlab.mixin.SetGet">matlab.mixin.SetGet</a> Methods:
	%    set                     - Set MATLAB object property values.
	%    get                     - Get MATLAB object properties.
	%    setdisp                 - Specialized MATLAB object property
	%                              display.
	%    getdisp                 - Specialized MATLAB object property
	%                              display.
	%
	% Inherited <a href="matlab:help handle">handle</a> Methods:
	%    addlistener             - Add listener for event.
	%    delete                  - Delete a handle object.
	%    eq                      - Test handle equality.
	%    findobj                 - Find objects with specified property
	%                              values.
	%    findprop                - Find property of MATLAB handle object.
	%    ge                      - Greater than or equal relation.
	%    gt                      - Greater than relation.
	%    isvalid                 - Test handle validity.
	%    le                      - Less than or equal relation for handles.
	%    lt                      - Less than relation for handles.
	%    ne                      - Not equal relation for handles.
	%    notify                  - Notify listeners of event.
	%
	% Inherited <a href="matlab:help matlab.mixin.CustomDisplay">matlab.mixin.CustomDisplay</a> Methods:
	%    details                 - Fully detailed formal object display.
	%    disp                    - Simple informal object display.
	%    display                 - Print variable name and display object.
	%
	% Inherited <a href="matlab:help matlab.mixin.Heterogeneous">matlab.mixin.Heterogeneous</a> Methods:
	%    cat                     - Concatenation for heterogeneous arrays.
	%    horzcat                 - Horizontal concatenation for
	%                              heterogeneous arrays.
	%    vertcat                 - Vertical concatenation for
	%                              heterogeneous arrays.
	%
	% Cursorbar Events:
	%    BeginDrag               - Notifies listeners that the dragging of
	%                              the Cursorbar has begun.
	%    EndDrag                 - Notifies listeners that the dragging of
	%                              the Cursorbar has ended.
	%    UpdateCursorBar         - Notifies listeners that the Cursorbar
	%                              has been updated.
	%
	% Inherited <a href="matlab:help handle">handle</a> Events:
	%    ObjectBeingDestroyed    - Notifies listeners that a particular
	%                              object has been destroyed.
	% Web:
	%    <a href="http://undocumentedmatlab.com/blog/undocumented-cursorbar-object">Undocumented Matlab: Undocumented cursorbar object</a>.
	%
	% See also:   graphics.Cursorbar.Cursorbar,     
	%             graphics.Cursorbar.getCursorInfo,
	%             graphics.Cursorbar.getMarkerLocations,
	%             graphics.Cursorbar.isTargetAxes,  
	%             graphics.Cursorbar.isTargetChart,
	%             .
	%             <a href="matlab:help cursorbar">cursorbar</a>, crossbar,
	%             graphics.Cursorbar.duplicate,     
	%             graphics.Cursorbar.drawCrossbar,
	%             .
	%             hobjects,                         
	%             graphics.Graphics,
	%             graphics.GraphicsPlaceholder,
	%             graphics.internal.CursorbarContainer.
	%
	% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for
	% MATLAB Graphics and for his contribution of new functionality.
	
	% Copyright 2003-2016 The MathWorks, Inc.
	
	% Change Log:
	%    13 Feb 2015: First version posted on the MathWorks file exchange:
	%                 <a href="http://www.mathworks.com/matlabcentral/fileexchange/49612-cursorbar">Cursorbar - File Exchange - MATLAB Central</a>.
	%    14 May 2015: Added a custom display; added logarithmic scale support; minor bug fixes.
	%    XX Jan 2016: Added saving and loading functionality; added empty allocation; 
	%                 improved construction time; improved stability; minor bug fixes.
	
	%% Public Properties
	
	properties
		Parent@handle           % Parent of Cursorbar
		
		% Line objects used to create larger drag surfaces for cursor line
		
		DisplayHandle@handle    % Display text handle
		TopHandle@handle        % Handle to the top (right) edge marker
		BottomHandle@handle     % Handle to the bottom (left) edge marker
		
		% Callbacks
		
		CreateFcn = ''    % Creation callback
		DeleteFcn = ''    % Deletion callback
		UpdateFcn = ''    % Update callback
		FigureCallbacks   % Additional Figure callbacks
		
		% Identifiers
		
		Tag@char = ''     % Tag to associate with the Cursorbar
		UserData          % Data to associate with the Cursorbar object
	end
	% --------------------------------------
	properties (Dependent)
		
		% Identifiers
		
		Annotation         % Legend icon display style
		DisplayName        % Text used by the legend
		
		% Parent/Child
		
		Children           % Children of Cursorbar
		HandleVisibility   % Visibility of object handle
		
		% Interactive Control
		
		Selected           % Selection state
		SelectionHighlight % Display of selection handles when selected
		
		% Callback Execution Control
		
		PickableParts      % Children that can capture mouse clicks
		HitTest            % Response to mouse clicks captured by children
		Interruptible      % Callback interruption
		BusyAction         % Callback queuing
		
		% Creation and Deletion Control
		
		BeingDeleted       % Deletion status of group
	end
	% --------------------------------------
	properties (SetObservable)
		Location@double = 0     % Location is a single value which is used to set the Position, based on the Orientation
		Position@double         % Position is used to set the location of main marker for the intersection
		
		% Handles
		
		Target@handle         	% Handle to the Target
		DataCursorHandle@handle % Handle to the Data Cursor
		UIContextMenu@handle    % Context menu
		
		% Cursor styles
		
		CursorLineColor@double = [0 0 0]  % Cursor line's color
		CursorLineStyle@char   = '-'      % Cursor line's style
		CursorLineWidth@double = 2        % Cursor line's width
		
		% Marker styles
		
		TopMarker@char = 'v'              % Top (right) edge marker shape
		BottomMarker@char = '^'           % Top (right) edge marker shape
		TargetMarkerStyle@char = 'square' % Target's marker style
		TargetMarkerSize@double= 8        % Target's marker size
		TargetMarkerEdgeColor  = [0 0 0]  % Target's marker outline color
		TargetMarkerFaceColor  = 'none'   % Target's marker fill color
	end
	% --------------------------------------
	properties (SetAccess=protected, SetObservable)
		ButtonDownFcn                     % Mouse-click callback
	end
	% --------------------------------------
	properties (SetAccess=immutable)
		Type = 'Cursorbar'                % Type of graphics object
	end
	
	% ============================================================= %
	
	%% Enumeration Properties
	
	properties (Constant)
		CursorbarShowText            = {'on','off'}                % Permitted Cursorbar ShowText options
		CursorbarOrientation         = {'vertical','horizontal'}   % Permitted Cursorbar Orientation options
		CursorbarTargetIntersections = {'multiple','single'}       % Permitted Cursorbar TargetIntersections options
		CursorbarTextDescription     = {'short','long'}            % Permitted Cursorbar TextDescription options
		
		% Classes of permitted targets
		PermittedChartTargets = {
			'matlab.graphics.chart.primitive.Line'
			'matlab.graphics.chart.primitive.Surface'
			'matlab.graphics.chart.primitive.Area'
			'matlab.graphics.chart.primitive.Bar'
			'matlab.graphics.chart.primitive.Contour'
			'matlab.graphics.chart.primitive.Histogram'
			'matlab.graphics.chart.primitive.Scatter'
			'matlab.graphics.chart.primitive.Stair'
			'matlab.graphics.chart.primitive.Stem'
			'matlab.graphics.primitive.Image'
			'matlab.graphics.primitive.Line'
			'matlab.graphics.primitive.Patch'
			'matlab.graphics.primitive.Surface'
			}
	end
	% --------------------------------------
	properties (SetObservable)
		ShowText@char            = 'on'       % Showing the Cursorbar Text {'on','off'}
		Orientation@char         = 'vertical' % Orientation of Cursorbar {'vertical','horizontal'}
		Visible@char             = 'on'       % Visibility of Cursorbar {'on','off'}
		TargetIntersections@char = 'multiple' % How many intersections are plotted {'multiple','single'}
		TextDescription@char     = 'short'    % Type of text description {'short','long'}
	end
	
	% ============================================================= %
	
	%% Hidden Properties
	
	properties (Hidden)
		TargetXData@double             % XData of Target
		TargetYData@double             % YData of Target
		TargetZData@double             % ZData of Target
		TargetNData@double             % NData of Target (which Target number out of several)
		
		CursorLineHandle@handle        % Line object used to represent the cursor bar
		TargetMarkerHandle@handle      % Line objects used to represent the intersection points with the Target
	end
	% --------------------------------------
	properties (Hidden, SetAccess=protected)
		DataCursorDummyTargetHandle@handle  % Line object placeholder for the DataCursor
		
		SelfListenerHandles@handle     % Self listeners
		TargetListenerHandles@handle   % Store listeners for Target
		ExternalListenerHandles@handle % Store other external listeners
		
		PeerHandle@graphics.Cursorbar                    % Handle to another Cursorbar object
		Container@graphics.internal.CursorbarContainer   % Handle to the Cursorbar's container
	end
	% --------------------------------------
	properties (Hidden, GetAccess=public, SetAccess=immutable)
		GroupHandle                    % The group containing all the objects
	end
	properties (GetAccess=protected, SetAccess=immutable)
		ObjectBeingCreated = true      % is the object being created
	end
	% --------------------------------------
	properties (Hidden, Constant)
		% Classes of permitted 2D targets
		Permitted2DTargets = {
			'matlab.graphics.chart.primitive.Surface'
			'matlab.graphics.chart.primitive.Area'
			'matlab.graphics.chart.primitive.Contour'
			'matlab.graphics.primitive.Image'
			'matlab.graphics.primitive.Patch'
			'matlab.graphics.primitive.Surface'
			}
	end
	
	% ============================================================= %
	
	%% Events
	
	events
		BeginDrag         % Notifies listeners that the dragging of the Cursorbar has begun.
		EndDrag           % Notifies listeners that the dragging of the Cursorbar has ended.
		UpdateCursorBar   % Notifies listeners that the Cursorbar has been updated.
	end
	
	% ============================================================= %
	
	%% Public methods
	
	% constructor
	methods
		function hThis = Cursorbar(hTarget,varargin)
			% CURSORBAR  A Cursorbar constructor
			%
			% See also: Cursorbar.
			
			% Check MATLAB Graphics system version
			if verLessThan('matlab','8.4.0')
				error('graphics:Cursorbar:Cursorbar:oldVersion', ...
					'Cursorbar requires the new MATLAB graphics system that was introduced in R2014b.');
			end
			
			% input error check
			narginchk(1,Inf);
			
			% validate correct property-value pair arguments
			assert( mod(length(varargin),2)==0 && iscellstr(varargin(1:2:end)), ...
				'graphics:Cursorbar:BadParamValuePairs', ...
				'Invalid parameter/value pair arguments.')
			
			% Initialize Cursorbar
			
			% force hTarget to column vector of handles
			hTarget = handle(hTarget(:));
			
			% get Cursorbar Parent and Target
			% don't set yet: this is to prevent creation of an empty
			%                figure when its HandleVisibility is off.
			if numel(hTarget) == 1
				if all(hThis.isTargetChart(hTarget))
					hParent = handle(ancestor(hTarget,'axes'));
				elseif isa(hTarget,'matlab.graphics.axis.Axes')
					hParent = handle(hTarget);
				else
					% delete Cursorbar and error if Target isn't a line or axes
					delete(hThis);
					error(message('MATLAB:cursorbar:InvalidTarget'));
				end
			else
				if all(hThis.isTargetChart(hTarget))
					hParent = handle(ancestor(hTarget(1),'axes'));
				else
					% delete Cursorbar if Target isn't a line or axes
					delete(hThis);
					error(message('MATLAB:cursorbar:InvalidTarget'));
				end
			end
			
			% set the parent & target property
			set(hThis,'Parent',hParent,'Target',hTarget);
			
			% set GroupHandle
			hThis.GroupHandle = hggroup('Parent',hParent);
			hThis.GroupHandle.Visible          = 'on';
			hThis.GroupHandle.PickableParts    = 'visible';
			hThis.GroupHandle.HandleVisibility = 'off';
			hThis.GroupHandle.Tag              = 'CursorbarGroup';
			hThis.GroupHandle.DisplayName      = 'Cursorbar';
			hThis.GroupHandle.DeleteFcn        = @(~,~)delete(hThis);
			hThis.GroupHandle.Serializable     = 'off'; % assert that none of the child handles is saved
			
			% add self property listeners
			localAddSelfListeners(hThis);
			
			% add listeners for the target and its ancestors
			localAddTargetListeners(hThis);
			
			% create Cursorbar and marker line
			hLines = localCreateNewCursorBarLines(hThis);
			set(hLines,'Parent',hThis.GroupHandle)
			
			% create context menu
			hCtxtMenu = localCreateUIContextMenu(hThis);
			set(hThis, 'UIContextMenu',hCtxtMenu)
			set(hLines,'UIContextMenu',hCtxtMenu)
			
			% set up the cursorbar containers for saving and loading
			localAddContainer(hThis,hParent);
			
			% set Position and Visible later, if they are specified as inputs
			visiblepropval     = '';
			positionpropval    = [];
			locationpropval    = [];
			orientationpropval = '';
			
			% Loop through and set specified properties
			if nargin>1
				for n = 1:2:length(varargin)
					propname = varargin{n};
					propval = varargin{n+1};
					%
					switch lower(propname)
						case 'visible'
							% Set the visible property at the end of this constructor
							% since the visible listener requires the DataTip to
							% be fully initialized.
							visiblepropval = validatestring(propval,{'on','off'});
						case 'position'
							% set the Position property just before setting Visible property
							% force to a row vector
							if numel(propval) > 3 || numel(propval) < 2 || ~isnumeric(propval) || ~all(isfinite(propval))
								error(message('MATLAB:graphics:cursorbar:invalidPosition'))
							end
							positionpropval = propval(:).';
						case 'location'
							locationpropval = propval;
						case 'orientation'
								orientationpropval = validatestring(propval,hThis.CursorbarOrientation);
						otherwise
							set(hThis,propname,propval);
					end
				end
			end
			
			% store vectors of Targets' XData and YData, sorted by Orientation
			[x,y,z,n] = getTargetXYData(hThis,orientationpropval);
			hThis.TargetXData = x;
			hThis.TargetYData = y;
			hThis.TargetZData = z;
			hThis.TargetNData = n;
			
			% create new DataCursor
			createNewDataCursor(hThis);
			
			% set Position
			if ~isempty(positionpropval)
				pos = positionpropval;
				pos(3) = 0; % ensure 1-by-3 vector
				% check Location
				if ~isempty(locationpropval)
					switch lower(orientationpropval)
						case 'vertical',   pos(1) = locationpropval;
						case 'horizontal', pos(2) = locationpropval;
						otherwise,         pos(1) = locationpropval;  % default vertical
					end
				end
				% set Position for DataCursor from input
				if isTargetAxes(hThis)
					% if the Target is an axes, use the Position directly
					set(hThis.DataCursorHandle.DataSource,'XData',pos(1),'YData',pos(2));
				else
					% not an axes
					[x,y] = closestvertex(hThis,pos,orientationpropval);
					pos = [x y 0];
					hThis.DataCursorHandle.Position = pos;
				end
			else % Position not set
				% set default Position
				hAxes = get(hThis,'Parent');
				xLim  = get(hAxes,'XLim');
				yLim  = get(hAxes,'YLim');
				pos   = [mean(xLim) mean(yLim) 0];
				% check Location
				if ~isempty(locationpropval)
					switch lower(orientationpropval)
						case 'vertical',   pos(1) = locationpropval;
						case 'horizontal', pos(2) = locationpropval;
						otherwise,         pos(1) = locationpropval;  % default vertical
					end
				end
				% set Position for DataCursor
				if isTargetAxes(hThis)
					% set the DataCursor's Position to the middle of the axes
					% use the 'pos' we already have
					set(hThis.DataCursorHandle.DataSource,'XData',pos(1),'YData',pos(2));
				else
					% choose the closest vertex to 'pos'
					[x,y] = closestvertex(hThis,pos,orientationpropval);
					pos = [x y 0];
					hThis.DataCursorHandle.Position = pos;
				end
			end
			
			% set Orientation
			if ~isempty(orientationpropval)
				set(hThis,'Orientation',orientationpropval);
			end
			
			% set Position and Location
			% set.Position silently sets Location
			hThis.Position = pos;

			% Set the visible property if it was passed into the constructor
			if ~isempty(visiblepropval)
				set(hThis,'Visible',visiblepropval)
			end

			% update
			% release ObjectBeingCreated constraint
			hThis.ObjectBeingCreated = false;
			% update Cursorbar
			update(hThis,[],[],'-nomove');
			
			% apply user's CreateFcn
			hThis.localApplyCreateFcn(hThis,[]);
		end
	end
	
	% ----------------------------------------
	
	%% Set Methods
	
	methods
		function s = setdisp(hThis)
			% SETDISP Customize set method display.
			s = set(hThis);
			
			% update
			s.ShowText              = graphics.Cursorbar.CursorbarShowText;
			s.Orientation           = graphics.Cursorbar.CursorbarOrientation;
			s.TargetIntersections   = graphics.Cursorbar.CursorbarTargetIntersections;
			s.TextDescription       = graphics.Cursorbar.CursorbarTextDescription;
			%
			s.CursorLineStyle       = {'-','--',':','-.','none'};
			s.TopMarker             = {'+','o','*','.','x','square','diamond','v','^','>','<','pentagram','hexagram','none'};
			s.BottomMarker          = {'+','o','*','.','x','square','diamond','v','^','>','<','pentagram','hexagram','none'};
			s.TargetMarkerStyle     = {'+','o','*','.','x','square','diamond','v','^','>','<','pentagram','hexagram','none'};
			s.TargetMarkerEdgeColor = {'none','flat','auto'};
			s.TargetMarkerFaceColor = {'none','flat','auto'};
			%
			s.BusyAction            = {'queue','cancel'};
			s.HandleVisibility      = {'on','callback','off'};
			s.Interruptible         = {'on','off'};
			s.HitTest               = {'on','off'};
			s.Visible               = {'on','off'};
			s.Selected              = {'on','off'};
			s.SelectionHighlight    = {'on','off'};
			s.PickableParts         = {'visible','none','all'};
			
			% show
			if nargout==0
				disp(s);
			end
		end
		% ----------------------------------------
		function set.ShowText(hThis,show)
			try
				show = validatestring(show,hThis.CursorbarShowText);
			catch ME,
				throwAsCaller(setmessage(ME,'ShowText'));
			end
			hThis.ShowText = show;
		end
		% ----------------------------------------
		function set.Orientation(hThis,orient)
			try
				orient = validatestring(orient,hThis.CursorbarOrientation);
			catch ME,
				throwAsCaller(setmessage(ME,'Orientation'));
			end
			hThis.Orientation = orient;
		end
		% ----------------------------------------
		function set.Visible(hThis,vis)
			try
				vis = validatestring(vis,{'on','off'});
			catch ME,
				throwAsCaller(setmessage(ME,'Visible'));
			end
			hThis.Visible = vis;
		end
		% ----------------------------------------
		function set.TargetIntersections(hThis,tin)
			try
				tin = validatestring(tin,hThis.CursorbarTargetIntersections);
			catch ME,
				throwAsCaller(setmessage(ME,'TargetIntersections'));
			end
			hThis.TargetIntersections = tin;
		end
		% ----------------------------------------
		function set.TextDescription(hThis,des)
			try
				des = validatestring(des,hThis.CursorbarTextDescription);
			catch ME,
				throwAsCaller(setmessage(ME,'TextDescription'));
			end
			hThis.TextDescription = des;
		end
		% ----------------------------------------
		function set.Location(hThis,loc)
			try
				validateattributes(loc,{'double'},{'scalar','real','finite'});
			catch ME,
				throwAsCaller(setmessage(ME,'Location'));
			end
			hThis.Location = loc;
		end
		% ----------------------------------------
		function set.Position(hThis,pos)
			try
				if numel(pos)==2, pos(3)=0; end % ensure a 3 element vector
				validateattributes(pos,{'double'},{'row','numel',3,'real','finite'});
			catch ME,
				throwAsCaller(setmessage(ME,'Position'));
			end
			hThis.Position = pos;
		end
		% ----------------------------------------
		function set.CreateFcn(hThis,fcn)
			if ischar(fcn) || isa(fcn,'function_handle') ...
					|| ( iscell(fcn) && (ischar(fcn{1}) || isa(fcn{1},'function_handle')) )
				hThis.CreateFcn = fcn;
			else
				ME = MException('MATLAB:datatypes:callback:CreateCallback', ...
					'Callback value must be a string, a function handle, or a cell array containing string or function handle');
				throwAsCaller(setmessage(ME,'CreateFcn'));
			end
		end
		% ----------------------------------------
		function set.DeleteFcn(hThis,fcn)
			if ischar(fcn) || isa(fcn,'function_handle') ...
					|| ( iscell(fcn) && (ischar(fcn{1}) || isa(fcn{1},'function_handle')) )
				hThis.DeleteFcn = fcn;
			else
				ME = MException('MATLAB:datatypes:callback:DeleteCallback', ...
					'Callback value must be a string, a function handle, or a cell array containing string or function handle');
				throwAsCaller(setmessage(ME,'DeleteFcn'));
			end
		end
		% ----------------------------------------
		function set.UpdateFcn(hThis,fcn)
			if ischar(fcn) || isa(fcn,'function_handle') ...
					|| ( iscell(fcn) && (ischar(fcn{1}) || isa(fcn{1},'function_handle')) )
				hThis.UpdateFcn = fcn;
			else
				ME = MException('MATLAB:datatypes:callback:UpdateCallback', ...
					'Callback value must be a string, a function handle, or a cell array containing string or function handle');
				throwAsCaller(setmessage(ME,'UpdateFcn'));
			end
		end
	end
	
	% ============================================================= %
	
	%% Dependent Methods
	
	methods
		function set.Annotation(hThis,val)
			try
				hThis.GroupHandle.Annotation = val;
			catch ME,
				throwAsCaller(setmessage(ME,'Annotation'));
			end
		end
		function val = get.Annotation(hThis)
			val = hThis.GroupHandle.Annotation;
		end
		% ----------------------------------------
		function set.DisplayName(hThis,val)
			try
				hThis.GroupHandle.DisplayName = val;
			catch ME,
				throwAsCaller(setmessage(ME,'DisplayName'));
			end
		end
		function val = get.DisplayName(hThis)
			val = hThis.GroupHandle.DisplayName;
		end
		% ----------------------------------------
		function set.Children(~,~)
			ME = MException('MATLAB:class:SetProhibited','You cannot set the read-only property ''Children'' of Class.');
			throwAsCaller(setmessage(ME,'Children'));
		end
		function val = get.Children(hThis)
			val = hThis.GroupHandle.Children;
		end
		% ----------------------------------------
		function set.HandleVisibility(hThis,val)
			try
				hThis.GroupHandle.HandleVisibility = val;
			catch ME,
				throwAsCaller(setmessage(ME,'HandleVisibility'));
			end
		end
		function val = get.HandleVisibility(hThis)
			val = hThis.GroupHandle.HandleVisibility;
		end
		% ----------------------------------------
		function set.Selected(hThis,val)
			try
				hThis.GroupHandle.Selected = val;
			catch ME,
				throwAsCaller(setmessage(ME,'Selected'));
			end
		end
		function val = get.Selected(hThis)
			val = hThis.GroupHandle.Selected;
		end
		% ----------------------------------------
		function set.SelectionHighlight(hThis,val)
			try
				hThis.GroupHandle.SelectionHighlight = val;
			catch ME,
				throwAsCaller(setmessage(ME,'SelectionHighlight'));
			end
		end
		function val = get.SelectionHighlight(hThis)
			val = hThis.GroupHandle.SelectionHighlight;
		end
		% ----------------------------------------
		function set.PickableParts(~,~)
			ME = MException('MATLAB:class:SetProhibited','You cannot set the read-only property ''PickableParts'' of Class.');
			throwAsCaller(setmessage(ME,'PickableParts'));
		end
		function val = get.PickableParts(hThis)
			val = hThis.GroupHandle.PickableParts;
		end
		% ----------------------------------------
		function set.HitTest(hThis,val)
			try
				hThis.GroupHandle.HitTest = val;
			catch ME,
				throwAsCaller(setmessage(ME,'HitTest'));
			end
		end
		function val = get.HitTest(hThis)
			val = hThis.GroupHandle.HitTest;
		end
		% ----------------------------------------
		function set.Interruptible(hThis,val)
			try
				hThis.GroupHandle.Interruptible = val;
			catch ME,
				throwAsCaller(setmessage(ME,'Interruptible'));
			end
		end
		function val = get.Interruptible(hThis)
			val = hThis.GroupHandle.Interruptible;
		end
		% ----------------------------------------
		function set.BusyAction(hThis,val)
			try
				hThis.GroupHandle.BusyAction = val;
			catch ME,
				throwAsCaller(setmessage(ME,'BusyAction'));
			end
		end
		function val = get.BusyAction(hThis)
			val = hThis.GroupHandle.BusyAction;
		end
		% ----------------------------------------
		function set.BeingDeleted(hThis,val)
			try
				hThis.GroupHandle.BeingDeleted = val;
			catch ME,
				throwAsCaller(setmessage(ME,'BeingDeleted'));
			end
		end
		function val = get.BeingDeleted(hThis)
			val = hThis.GroupHandle.BeingDeleted;
		end
	end
	
	% ============================================================= %
	
	%% Sealed Methods
	
	methods (Sealed)
		function tf = ishandle(hThis)
			% ISHANDLE  Checks on self if valid handle
			%
			% See also ishandle, graphics.Cursorbar.
			tf = isvalid(hThis);
		end
	end
	
	% ============================================================= %
	
	%% Local (Protected Hidden) Methods
	
	methods (Access=protected, Hidden)
		
		function localApplyCreateFcn(hThis,obj,evd)
			% LOCALAPPLYCREATEFCN  Apply the create function.
			localApplyCallbackFcn(hThis,obj,evd,'CreateFcn');
		end
		
		% --------------------------------------
		function localApplyDeleteFcn(hThis,obj,evd)
			% LOCALAPPLYDELETEFCN  Apply the delete function.
			localApplyCallbackFcn(hThis,obj,evd,'DeleteFcn');
		end
		
		% --------------------------------------
		function localApplyUpdateFcn(hThis,obj,evd)
			% LOCALAPPLYDELETEFCN  Apply the delete function.
			localApplyCallbackFcn(hThis,obj,evd,'UpdateFcn');
		end
		
		% --------------------------------------
		function localApplyCallbackFcn(hThis,obj,evd,callbackname)
			% LOCALAPPLYCALLBACKFCN  Apply some callback function.
			func = hThis.(callbackname);
			try % to apply delete function
				switch class(func)
					case 'char',             eval(func);
					case 'function_handle', feval(func,obj,evd);
					case 'cell',            feval(hThis.func{1},obj,evd,hThis.func{2:end});
				end
			catch ME, % warn quietly
				wME = setmessage(ME,callbackname);
				warning(wME.identifier, wME.message);
			end
		end
		
		% --------------------------------------
		function hLines = localCreateNewCursorBarLines(hThis,~,~)
			% LOCALCREATENEWCURSORBARLINES create lines for Cursorbar, and line for markers
			
			% Get axes and figure
			hAxes   = get(hThis,'Parent');
			hGroup  = hThis.GroupHandle;

			% white line on dark axes, black line on light axes
			AXCOLOR = get(hAxes,'Color');
			
			% --------- cursor line ---------
			lineprops                  = struct;
			lineprops.Tag              = 'DataCursorLine';
			lineprops.Parent           = hGroup;
			lineprops.XData            = [NaN NaN];
			lineprops.YData            = [NaN NaN];
			lineprops.Color            = hThis.CursorLineColor;
			%
			% light colored axes
			if sum(AXCOLOR) < 1.5
				lineprops.Color         = [1 1 1];
			end
			%
			lineprops.Marker           = 'none';
			lineprops.LineStyle        = '-';
			lineprops.LineWidth        = 2;
			%
			lineprops.Clipping         = 'on';
			lineprops.XLimInclude      = 'off'; % don't interfere with axes zooming
			lineprops.YLimInclude      = 'off'; % don't interfere with axes zooming
			%
			lineprops.HandleVisibility = 'off';
			lineprops.Visible          = hThis.Visible;
			lineprops.ButtonDownFcn    = @hThis.localCursorButtonDownFcn;
			lineprops.Serializable     = 'off'; % don't save to file

			cursorline                 = line(lineprops);
			hThis.CursorLineHandle     = handle(cursorline);
			hThis.ButtonDownFcn        = lineprops.ButtonDownFcn;

			% --------- top,bottom affordances ---------
			lineprops.XData            = NaN;
			lineprops.YData            = NaN;
			lineprops.MarkerFaceColor  = hThis.CursorLineColor;
			lineprops.LineStyle        = 'none';
			%
			% top
			lineprops.Tag              = 'DataCursorLineTop';
			lineprops.Marker           = hThis.TopMarker;
			%
			topdragline                = line(lineprops);
			hThis.TopHandle            = handle(topdragline);
			%
			% bottom
			lineprops.Tag              = 'DataCursorLineBottom';
			lineprops.Marker           = hThis.BottomMarker;
			%
			bottomdragline             = line(lineprops);
			hThis.BottomHandle         = handle(bottomdragline);

			% --------- marker line ---------
			lineprops.Tag              = 'DataCursorTargetMarker';
			lineprops.Marker           = hThis.TargetMarkerStyle;
			lineprops.MarkerSize       = hThis.TargetMarkerSize;
			lineprops.MarkerEdgeColor  = hThis.TargetMarkerEdgeColor;
			lineprops.MarkerFaceColor  = hThis.TargetMarkerFaceColor;
			lineprops.LineStyle        = 'none';
			%
			markerline                 = line(lineprops);
			hThis.TargetMarkerHandle   = handle(markerline);
			
			% combine handles
			hLines = handle([  ...
				cursorline;
				topdragline;
				bottomdragline;
				markerline ]);
		end
		
		% --------------------------------------
		function hCtxtMenu = localCreateUIContextMenu(hThis,~,~)
			% LOCALCREATEUICONTEXTMENU
			
			if ismethod(hThis,'createUIContextMenu')
				hCtxtMenu = hThis.createUIContextMenu();
			else
				hCtxtMenu = hThis.defaultUIContextMenu();
			end
		end
		
		% --------------------------------------
		function localAddTargetListeners(hThis,~,~)
			% LOCALADDTARGETLISTENERS add listeners for Target and its parent axes
			
			% check Target
			hTarget = hThis.Target;
			if ~ishandle(hTarget)
				return;
			end
			
			% get handles for axes
			hAxes = handle(get(hThis,'Parent'));
			
			% listen for changes to axes' Limits
			axesLimProps = [  ...
				findprop(hAxes,'XLim');
				findprop(hAxes,'YLim');
				findprop(hAxes,'ZLim')];
			l = event.proplistener(hAxes,axesLimProps,'PostSet',@hThis.localAxesLimUpdate);
			
			% Update if Target is line(s) and any target ...Data property changes
			if ~isTargetAxes(hThis)
				for n = 1:length(hTarget)
					target_prop = [  ...
						findprop(hTarget(n),'XData');
						findprop(hTarget(n),'YData');
						findprop(hTarget(n),'ZData')];
					l(end+1) = event.proplistener(hTarget(n),target_prop,'PostSet',...
						@hThis.localTargetDataUpdate); %#ok<AGROW>
				end
			end
			
			% Listen to axes pixel bound resize events
			axes_prop = findprop(hAxes,'PixelBound');
			l(end+1) = event.proplistener(hAxes,axes_prop, 'PostSet',...
				@hThis.localAxesPixelBoundUpdate);
			
			% Clean up if Cursorbar or its Target is deleted
			l(end+1) = event.listener(hThis.Target,'ObjectBeingDestroyed',...
				@hThis.localTargetDestroy);
			
			% Store listeners
			hThis.TargetListenerHandles = l;
		end
		
		% --------------------------------------
		function localAddSelfListeners(hThis,~,~)
			% LOCALADDSELFLISTENERS add listeners to Cursorbar's properties
			
			% Visible
			l(  1  ) = event.proplistener(hThis,findprop(hThis,'Visible'),...
				'PostSet',@hThis.localSetVisible);
			
			% ShowText
			l(end+1) = event.proplistener(hThis,findprop(hThis,'ShowText'),...
				'PostSet',@hThis.localSetShowText);
			
			% TargetIntersections
			l(end+1) = event.proplistener(hThis,findprop(hThis,'TargetIntersections'),...
				'PostSet',@hThis.localSetTargetIntersections);
			
			% TextDescription
			l(end+1) = event.proplistener(hThis,findprop(hThis,'TextDescription'),...
				'PostSet',@hThis.localSetTextDescription);
			
			% Orientation
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Orientation'),...
				'PostSet',@hThis.localSetOrientation);
			
			% Location
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Location'),...
				'PostSet',@hThis.localSetLocation);
			
			% Position
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Position'),...
				'PostSet',@hThis.localSetPosition);
			
			% UIContextMenu
			l(end+1) = event.proplistener(hThis,findprop(hThis,'UIContextMenu'),...
				'PostSet',@hThis.localSetUIContextMenu);
			
			% ButtonDownFcn
			l(end+1) = event.proplistener(hThis,findprop(hThis,'ButtonDownFcn'),...
				'PostSet', @hThis.localSetButtonDownFcn);
			
			% Target
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Target'),...
				'PreSet', @hThis.localPreSetTarget);
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Target'),...
				'PostSet', @hThis.localPostSetTarget);
			l(end+1) = event.proplistener(hThis,findprop(hThis,'Target'),...
				'PostSet', @hThis.localAddTargetListeners);
			
			% Cursorbar appearance properties
			p = [  ...
				findprop(hThis,'CursorLineColor');
				findprop(hThis,'CursorLineStyle');
				findprop(hThis,'CursorLineWidth');
				findprop(hThis,'TopMarker');
				findprop(hThis,'BottomMarker')];
			l(end+1) = event.proplistener(hThis,p,'PostSet', @hThis.localSetCursorProps);
			
			% Marker properties
			p = [  ...
				findprop(hThis,'TargetMarkerStyle');...
				findprop(hThis,'TargetMarkerSize'); ...
				findprop(hThis,'TargetMarkerEdgeColor'); ... % YD
				findprop(hThis,'TargetMarkerFaceColor'); ... % YD
				];
			l(end+1) = event.proplistener(hThis,p,'PostSet',@hThis.localSetMarkerProps);
			
			% Listen for update event
			l(end+1) = event.listener(hThis,'UpdateCursorBar',@hThis.updateDisplay);
			
			% Clean up if Cursorbar is deleted
			l(end+1) = event.listener(hThis,'ObjectBeingDestroyed',...
				@hThis.localCursorBarDestroy);
			
			% Store listeners
			hThis.SelfListenerHandles = l;
			
		end
		
		% --------------------------------------
		function localAxesPixelBoundUpdate(hThis,~,~)
			% LOCALAXESPIXELBOUNDUPDATE
			
			update(hThis);
		end
		
		% --------------------------------------
		function localSetOrientation(hThis,~,evd)
			% LOCALSETORIENTATION
			
			% get new Orientation value
			newval = evd.AffectedObject.Orientation;
			
			% get DataCursor's Position
			pos = hThis.DataCursorHandle.Position;
			x = pos(1);
			y = pos(2);
			
			hAxes = get(hThis,'Parent');
			
			% get axes' limits
			xlimits = get(hAxes,'XLim');
			ylimits = get(hAxes,'YLim');
			
			% get axes' directions
			xdir = get(hAxes,'XDir');
			ydir = get(hAxes,'YDir');
			
			% setting Marker for 'affordances' at ends of Cursorbar
			switch newval
				case 'vertical'
					set(hThis.CursorLineHandle,'XData',[x x],'YData',ylimits);
					switch ydir
						case 'normal'
							set(hThis.BottomHandle,'Marker','^')
							set(hThis.TopHandle,'Marker','v')
						case 'reverse'
							set(hThis.BottomHandle,'Marker','v')
							set(hThis.TopHandle,'Marker','^')
					end
				case 'horizontal'
					set(hThis.CursorLineHandle,'XData',xlimits,'YData',[y y]);
					switch xdir
						case 'normal'
							set(hThis.BottomHandle,'Marker','<')
							set(hThis.TopHandle,'Marker','>')
						case 'reverse'
							set(hThis.BottomHandle,'Marker','>')
							set(hThis.TopHandle,'Marker','<')
					end
				otherwise
					error(message('MATLAB:graphics:cursorbar:invalidOrientation'))
			end
			
			% update Cursorbar
			if ~isempty(hThis.Position)
				hThis.Position = hThis.Position; % silently update Location and Position
			end
			% update(hThis)
			
		end
		
		% --------------------------------------
		function localSetLocation(hThis,~,evd)
			% LOCALSETLOCATION
			
			loc = evd.AffectedObject.Location;
			
			pos = get(hThis,'Position');
			
			% during initialization (duplication) the position may not be set yet;
			% assert proper length (=3)
			if length(pos)<3
				pos(1,3) = 0;
			end
			
			switch get(hThis,'Orientation')
				case 'vertical'
					pos(1) = loc;
				case 'horizontal'
					pos(2) = loc;
				otherwise % default vertical
					pos(1) = loc;
			end
			
			% set(hThis.DataCursorHandle,'Position',pos)
			set(hThis,'Position',pos)
			
			% update(hThis); % set.Position already updates Cursorbar
		end
		
		% --------------------------------------
		function localSetPosition(hThis,~,evd)
			% LOCALSETPOSITION
			
			% return early if not a handle
			if ~ishandle(hThis)
				return;
			end
			
			% get new Position
			pos = evd.AffectedObject.Position;
			
			% Position should be [X Y] or [X Y Z]
			if numel(pos) ~= 2 && numel(pos) ~= 3
				return
			end
			
			x = pos(1);
			y = pos(2);
			
			hCursorLine = hThis.CursorLineHandle;
			hTopLine    = hThis.TopHandle;
			hBottomLine = hThis.BottomHandle;
			hAxes       = get(hThis,'Parent');
			
			switch get(hThis,'Orientation')
				case 'vertical'
					if isempty(hThis.Location) || hThis.Location ~= x
						set(hThis,'Location',x);
					end
					
					yLim = get(hAxes,'YLim');
					set(hCursorLine,'XData',[x x],'YData',yLim);
					set(hBottomLine,'XData',x,    'YData',yLim(1));
					set(hTopLine,   'XData',x,    'YData',yLim(2));
				case 'horizontal'
					if isempty(hThis.Location) || hThis.Location ~= y
						set(hThis,'Location',y);
					end
					xLim = get(hAxes,'XLim');
					set(hCursorLine,'XData',xLim,   'YData',[y y]);
					set(hBottomLine,'XData',xLim(2),'YData',y);
					set(hTopLine,   'XData',xLim(1),'YData',y);
			end
			
			% silently update
			updateMarkers(hThis);
			updateDisplay(hThis);
			% defaultUpdateFcn(hThis,obj,evd);
			
		end
		
		% --------------------------------------
		function localSetShowText(hThis,obj,evd)
			% LOCALSETSHOWTEXT
			
			validhandles = ishandle(hThis.DisplayHandle);
			visibility   = evd.AffectedObject.ShowText;
			set(hThis.DisplayHandle(validhandles),'Visible',visibility);
			%
			hThis.updateDisplay(obj,evd); % update display
		end
		
		% --------------------------------------
		function localSetTargetIntersections(hThis,obj,evd)
			% LOCALSETTARGETINTERSECTION
			
			hThis.updateMarkers();        % update markers
			hThis.updateDisplay(obj,evd); % update display
		end
		
		% --------------------------------------
		function localSetTextDescription(hThis,obj,evd)
			% LOCALSETTEXTDESCRIPTION
			
			hThis.updateMarkers();        % update markers
			hThis.updateDisplay(obj,evd); % update display
		end
		
		% --------------------------------------
		function localSetUIContextMenu(hThis,~,evd)
			% LOCALSETUICONTEXTMENU
			
			contextmenu = evd.AffectedObject.UIContextMenu;
			
			hndls = [
				hThis.CursorLineHandle;
				hThis.TargetMarkerHandle;
				hThis.TopHandle;
				hThis.BottomHandle;
				hThis.GroupHandle];
			
			set(hndls,'UIContextMenu',contextmenu);
		end
		
		% --------------------------------------
		function localSetButtonDownFcn(hThis,~,evd)
			% LOCALSETBUTTONDOWNFCN
			
			newVal = evd.AffectedObject.ButtonDownFcn;
			
			hLines = [
				hThis.CursorLineHandle;
				hThis.TargetMarkerHandle;
				hThis.TopHandle
				hThis.BottomHandle
				hThis.GroupHandle];
			
			set(hLines,'ButtonDownFcn',newVal);
		end
		
		% --------------------------------------
		function localSetCursorProps(hThis,~,evd)
			% LOCALSETCURSORPROPS
			
			propname = evd.Source.Name;
			propval  = evd.AffectedObject.(propname);
			
			switch propname
				case 'CursorLineColor'
					newpropname = 'Color';
					hLine = [hThis.CursorLineHandle; hThis.TopHandle; hThis.BottomHandle];
				case 'CursorLineStyle'
					newpropname = 'LineStyle';
					hLine = hThis.CursorLineHandle;
				case 'CursorLineWidth'
					newpropname = 'LineWidth';
					hLine = hThis.CursorLineHandle;
				case 'TopMarker'
					newpropname = 'Marker';
					hLine = hThis.TopHandle;
				case 'BottomMarker'
					newpropname = 'Marker';
					hLine = hThis.BottomHandle;
			end
			
			set(hLine,newpropname,propval);
		end
		
		% --------------------------------------
		function localSetMarkerProps(hThis,~,evd)
			% LOCALSETMARKERPROPS
			
			propname = evd.Source.Name;
			propval  = evd.AffectedObject.(propname);
			
			switch propname
				case 'TargetMarkerStyle'
					newpropname = 'Marker';
				case 'TargetMarkerSize'
					newpropname = 'MarkerSize';
				case 'TargetMarkerEdgeColor' % YD
					newpropname = 'MarkerEdgeColor';
				case 'TargetMarkerFaceColor' % YD
					newpropname = 'MarkerFaceColor';
			end
			
			set(hThis.TargetMarkerHandle,newpropname,propval)
		end
		
		% --------------------------------------
		function localPreSetTarget(hThis,~,evd)
			% LOCALPRESETTARGET
			
			% check new Target value
			newTarget = evd.AffectedObject.Target;
			if ~all(isTargetChart(hThis)) && ~isa(newTarget,'matlab.graphics.axis.Axes')
				error(message('MATLAB:cursorbar:InvalidTarget'));
			end
			
			% remove the old container
			localRemoveContainer(hThis);
		end
		
		% --------------------------------------
		function localPostSetTarget(hThis,~,~)
			% LOCALPOSTSETTARGET
			
			% set up the container
			localAddContainer(hThis);
			
			% if it's a line, set it close to the current location of the Cursorbar
			if isTargetAxes(hThis)
				% do nothing for axes, no need to change Position
				return
			end
			
			% update the Target...Data
			[x,y,z,n] = getTargetXYData(hThis);
			hThis.TargetXData = x;
			hThis.TargetYData = y;
			hThis.TargetZData = z;
			hThis.TargetNData = n;
		
			% update Cursorbar
			hThis.update([],[],'-nomove');
		end
		
		% --------------------------------------
		function localSetVisible(hThis,obj,evd)
			% LOCALSETVISIBLE
			
			% Return early if no DataCursor
			if ~isvalid(hThis.DataCursorHandle) || isempty(hThis.DataCursorHandle.Position)
				hThis.Visible = 'off';
				hThis.GroupHandle.Visible = 'off';
				hThis.updateDisplay(obj,evd);
				return;
			end
			
			newvalue = evd.AffectedObject.Visible;
			hThis.GroupHandle.Visible = newvalue;
			hThis.updateDisplay(obj,evd);
		end
		
		% --------------------------------------
		function localAddContainer(hThis,hParent)
			% LOCALADDCONTAINER  Add a CursorbarContainer to the parent
			
			% inputs
			if nargin<2
				hParent = hThis.Parent;                   % default parent
			end
			hFig       = ancestor(hParent,'figure');     % figure handle
			
			% store the application data in the parent axes for serialization reasons
			key        = graphics.internal.CursorbarContainer.Key; % application data key
			containers = getappdata(hFig,key);                     % retrieve Cursorbar containers
			%
			if  isempty(containers) || ~any(containers.hasCursorbar(hThis))
				% create a new container and store
				newContainer    = graphics.internal.CursorbarContainer(hThis);% container of the current object
				containers      = [containers newContainer];        % add the current container
				%
				setappdata(hFig,key,containers);                    % store all the containers in the parent
				hThis.Container = newContainer;                     % store the new container
			end
		end
		
		% --------------------------------------
		function localRemoveContainer(hThis,hParent)
			% LOCALREMOVECONTAINER  Remove the CursorbarContainer from the parent
			
			% inputs
			if nargin<2
				hParent = hThis.Parent;                   % default parent
			end
			hFig       = ancestor(hParent,'figure');     % figure handle
			
			% remove the application data in the parent axes
			key        = graphics.internal.CursorbarContainer.Key; % application data key
			containers = getappdata(hFig,key);                     % retrieve Cursorbar containers
			%
			if ~isempty(containers) && any(containers.hasCursorbar(hThis))
				% remove containers from the application data
				current = containers.hasCursorbar(hThis);           % containers for the current object
				setappdata(hFig,key,containers(~current));          % leave only the non-current containers
			end
			
			% delete the old container handle
			if isvalid(hThis.Container)
				delete(hThis.Container);
			end
		end
		
		% --------------------------------------
		function localCursorBarDestroy(hThis,~,~,varargin)
			% LOCALCURSORBARDESTROY called when the Cursorbar is destroyed
			
			% user defined delete function
			hThis.localApplyDeleteFcn(hThis,[]);
			
			% remove cursorbar containers
			if ishandle(hThis.Parent)
				localRemoveContainer(hThis,hThis.Parent);
			end
			
			% delete all child objects
			if ishandle(hThis.CursorLineHandle)
				delete(hThis.CursorLineHandle);
			end
			if ishandle(hThis.TargetMarkerHandle)
				delete(hThis.TargetMarkerHandle);
			end
			if ishandle(hThis.TopHandle)
				delete(hThis.TopHandle);
			end
			if ishandle(hThis.BottomHandle)
				delete(hThis.BottomHandle);
			end
			if isvalid(hThis.DataCursorHandle)
				delete(hThis.DataCursorHandle)
			end
			validhandles = ishandle(hThis.DisplayHandle);
			if any(validhandles)  && all(isa(hThis.DisplayHandle(validhandles),'matlab.graphics.primitive.Text'))
				delete(hThis.DisplayHandle(validhandles))
			end
			if ishandle(hThis.GroupHandle)
				delete(hThis.GroupHandle)
			end
		end
		
		% --------------------------------------
		function localTargetDestroy(hThis,~,evd,varargin)
			% LOCALTARGETDESTROY called when the any of the Cursorbar's Target objects are destroyed
			
			% if there is a single Target, then Cursorbar should be destroyed when it is
			% destroyed
			if length(hThis.Target) == 1
				delete(hThis);
				return
			else
				% determine which Target was deleted
				deletedTarget = evd.Source;
				
				% remove from Target list
				hTargets = handle(hThis.Target);
				hTargets(hTargets == deletedTarget) = [];
				set(hThis,'Target',hTargets);
				
				% update the Target_Data
				[x,y,z,n] = getTargetXYData(hThis);
				hThis.TargetXData = x;
				hThis.TargetYData = y;
				hThis.TargetZData = z;
				hThis.TargetNData = n;
		end
			
			update(hThis,[],[],'-nomove');
		end
		
		% --------------------------------------
		function localAxesLimUpdate(hThis,~,~)
			% LOCALAXESLIMUPDATE update cursor line after limits change
			
			% get the Cursorbar's orientation
			orient = get(hThis,'Orientation');
			
			hAxes = handle(get(hThis,'Parent'));
			hCursorLine = get(hThis,'CursorLineHandle');
			
			switch orient
				case 'vertical'
					ylim = get(hAxes,'YLim');
					set(hCursorLine,'YData',ylim)
				case 'horizontal'
					xlim = get(hAxes,'XLim');
					set(hCursorLine,'XData',xlim)
			end
		end
		
		% --------------------------------------
		function localTargetDataUpdate(hThis,~,~,varargin)
			% LOCALTARGETDATAUPDATE
			
			hDataCursor = hThis.DataCursorHandle;
			
			oldpos = hDataCursor.Position;
			
			% use the old position to determine the new position
			[x,y] = closestvertex(hThis,oldpos);
			pos = [x y 0];
			hDataCursor.Position = pos;
			update(hThis);
		end
		
		% --------------------------------------
		function localCursorButtonDownFcn(hThis,~,~)
			% LOCALCURSORBUTTONDOWNFCN click on Cursorbar
			
			hFig = ancestor(hThis,'Figure');
			
			% swap out the WindowButton...Fcns
			uistate = struct;
			uistate.WindowButtonUpFcn     = get(hFig,'WindowButtonUpFcn');
			uistate.WindowButtonMotionFcn = get(hFig,'WindowButtonMotionFcn');
			uistate.Pointer = get(hFig,'Pointer');
			
			% save figure's current state
			setappdata(hFig,'CursorBarOriginalFigureCallbacks',uistate);
			
			% modify uistate
			uistate.WindowButtonUpFcn     = @hThis.localWindowButtonUpFcn;
			uistate.WindowButtonMotionFcn = @hThis.localWindowButtonMotionFcn;
			uistate.Pointer = 'fleur';
			
			% set new state
			set(hFig,uistate);
			
			% send BeginDrag event
			notify(hThis,'BeginDrag');
		end
		
		% --------------------------------------
		function localWindowButtonMotionFcn(hThis,~,~)
			% LOCALWINDOWBUTTONMOTIONFCN move Cursorbar
			
			% update the Cursorbar while moving
			update(hThis);
		end
		
		% --------------------------------------
		function localWindowButtonUpFcn(hThis,hFig,~)
			% LOCALWINDOWBUTTONUPFCN restore original figure callbacks and pointer
			
			% get stored callbacks
			uistate = getappdata(hFig,'CursorBarOriginalFigureCallbacks');
			
			if ~isempty(uistate)
				set(hFig,uistate);
			end
			
			% send EndDrag event
			notify(hThis,'EndDrag');
		end
		
		% --------------------------------------
		function localTestUpdate(~,~,evd)
			% LOCALTESTUPDATE test for property listeners
			
			disp(get(evd))
			
		end
	end
	
	% ============================================================= %
	
	%% Folder (Protected Hidden) Methods
	methods (Access=protected, Hidden)
		% --------------------------------------
		uictxtmenu = defaultUIContextMenu(hThis);
		% --------------------------------------
		defaultUpdateFcn(hThis,obj,evd);
		% --------------------------------------
		[xIntersect,yIntersect,hIntersect] = getIntersections(hThis,hLines);
		% --------------------------------------
		pixperdata = getPixelsPerData(hThis);
		% --------------------------------------
		[x,y,z,n] = getTargetXYData(hThis,orient);
		% --------------------------------------
		move(hThis,dir);
		% --------------------------------------
		moveDataCursor(hThis,hDataCursor,direc);
		% --------------------------------------
		update(hThis,obj,evd,varargin)
		% --------------------------------------
		updateDataCursor(hThis,hNewDataCursor,target)
		% --------------------------------------
		updateDisplay(hThis,obj,evd)
		% --------------------------------------
		updateMarkers(hThis)
		% --------------------------------------
		updatePosition(hThis,hNewDataCursor)
		% --------------------------------------
		hNewDataCursor = createNewDataCursor(hThis,hTarget)
		% --------------------------------------
		[x,y,n] = closestvertex(hThis,pos,orient)
	end
	
	% ============================================================= %
	
	%% Custom Display Methods
	
	methods(Access = protected)
				
		% --------------------------------------
		function groups = getScalarPropertyGroups(hThis) %#ok<MANU>
			% GETSCALARPROPERTYGROUPS  Construct array of property groups for display of scalar case.
			
			% Scalar case: change order
			propList = { ...
				'Location',  ...
				'Position',  ...
				'Orientation', ...
				...
				'CursorLineColor', ...
				'CursorLineStyle', ...
				'CursorLineWidth', ...
				'TopMarker', ...
				'BottomMarker', ...
				...
				'TargetMarkerStyle', ...
				'TargetMarkerSize', ...
				'TargetMarkerEdgeColor', ...
				'TargetMarkerFaceColor', ...
				...
				'ShowText', ...
				'TargetIntersections', ...
				'TextDescription' ...
				};
			groups = matlab.mixin.util.PropertyGroup(propList);
		end
	end
	
	% ============================================================= %
	
end

% ============================================================= %

%% Subfunctions

function newME = setmessage(ME,prop)
% SETMESSAGE  Sets the error message for set.Property functions.
classLink  = sprintf('<a href="matlab:doc %s">Cursorbar</a>',mfilename('class'));
%
firstLine  = sprintf('While setting the ''%s'' property of %s:',prop,classLink);
messageStr = regexprep(ME.message,'Class',classLink);
identifier = regexprep(ME.identifier,{'\<MATLAB\>','\.'},{mfilename('class'),':'},'ignorecase');
%
newME      = MException(identifier,'%s\n%s',firstLine,messageStr);
end

%% EOF
