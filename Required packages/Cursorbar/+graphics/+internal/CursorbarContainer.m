classdef (ConstructOnLoad=true) CursorbarContainer < handle
	% CursorbarContainer  Container class for a graphics.Cursorbar objects.
	%
	% Container class for graphics.Cursorbar objects, where de-serialization
	% restores the links.
	%
	% MCOS graphics cannot rely on custom machinery in load to restore
	% Cursorbar listeners. Instead, create a CursorbarContainer to wrap the
	% Cursorbar, which will restore the listeners when it is de-serialized.
	%
	% CursorbarContainer requires the new MATLAB graphics system that was
	% introduced in R2014b
	%
	% Usage:
	%    CursorbarContainer()           - Creates a CursorbarContainer
	%                                     without linked Cursorbar handle.
	%    CursorbarContainer(hCursorbar) - Creates a CursorbarContainer for
	%                                     the specified Cursorbar handle.
	%
	% CursorbarContainer Constructor:
	%    CursorbarContainer      - CursorbarContainer constructor.
	%
	% CursorbarContainer Properties:
	%    Key                     - The key to the stored application data
	%    Target                  - Targets of the Cursorbar
	%    PropertyValues          - Property-value pairs of the Cursorbar
	%    CursorbarHandle         - The Cursorbar handle
	%
	% CursorbarContainer Methods:
	%    saveobj                 - Serialize the Target and PropertyValues.
	%    hasCursorbar            - Checks if the CursorbarContainer contains
	%                              the current cursorbar.
	%
	% CursorbarContainer Static Methods:
	%    loadobj                 - Restore the Cursorbar listeners on
	%                              de-serialization.
	%    getCursorbars           - Get all the cursorbars from the current
	%                              figure.
	%    getContainers           - Get all the containers from the current
	%                              figure.
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
	% Inherited <a href="matlab:help handle">handle</a> Events:
	%    ObjectBeingDestroyed    - Notifies listeners that a particular
	%                              object has been destroyed.
	% Web:
	%    <a href="http://undocumentedmatlab.com/blog/undocumented-cursorbar-object">Undocumented Matlab: Undocumented cursorbar object</a>.
	%
	% See also: Cursorbar.
	%
	% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for
	% MATLAB Graphics and for his contribution of new functionality.
	
	% This class is based on linkaxes and matlab.graphics.internal.LinkAxes.
	
	% Copyright 2016 The MathWorks, Inc.
	
	
	%% Properties
	properties (Constant)
		Key = 'GraphicsCursorbarContainer'    % The key to the stored application data
	end
	
	% --------------------------------------
	
	properties (SetAccess = 'protected')
		Target@handle                         % Targets of the Cursorbar
		PropertyValues                        % Property-value pairs of the Cursorbar
	end
	
	% --------------------------------------
	
	properties (Transient)
		CursorbarHandle@graphics.Cursorbar scalar            % The Cursorbar handle
	end
	
	properties (SetAccess = 'protected', Hidden)
		PeerContainer@graphics.internal.CursorbarContainer   % A handle to a container's Peer, if Cursorbar also has one
	end
	
	%% Main Methods
	
	methods
		
		function hThis = CursorbarContainer(hCursorbar)
			% CURSORBARCONTAINER  A CursorbarContainer constructor.
			%
			% See also: CursorbarContainer.
			
			% Check MATLAB Graphics system version
			if verLessThan('matlab','8.4.0')
				error('graphics:internal:CursorbarContainer:CursorbarContainer:oldVersion', ...
					'CursorbarContainer requires the new MATLAB graphics system that was introduced in R2014b.');
			end
			
			% call handle constructor
			hThis = hThis@handle;
			
			% set up the Cursorbar handles
			% each container can hold only a single Cursorbar
			if nargin==1
				validateattributes(hCursorbar,{'graphics.Cursorbar'},{'nonempty'});
				%
				for i=numel(hCursorbar):-1:1
					hThis(i).CursorbarHandle = hCursorbar(i);
				end
				reshape(hThis,size(hCursorbar));
			end
		end
		
		% --------------------------------------
		
		function hThis = saveobj(hThis)
			% SAVEOBJ  Serialize the Target and PropertyValues.
			
			% set the target and the property values right before serialization;
			if ~isempty(hThis.CursorbarHandle)
				hThis.Target = hThis.CursorbarHandle.Target;
				hThis.PropertyValues = { ...
					'BottomMarker',            hThis.CursorbarHandle.BottomMarker, ...
					'CreateFcn',               hThis.CursorbarHandle.CreateFcn, ...
					'CursorLineColor',         hThis.CursorbarHandle.CursorLineColor, ...
					'CursorLineStyle',         hThis.CursorbarHandle.CursorLineStyle, ...
					'CursorLineWidth',         hThis.CursorbarHandle.CursorLineWidth, ...
					'DeleteFcn',               hThis.CursorbarHandle.DeleteFcn, ...
					'DisplayName',             hThis.CursorbarHandle.DisplayName, ...
					'FigureCallbacks',         hThis.CursorbarHandle.FigureCallbacks, ...
					'HitTest',                 hThis.CursorbarHandle.HitTest, ...
					'Interruptible',           hThis.CursorbarHandle.Interruptible, ...
					'Location',                hThis.CursorbarHandle.Location, ...
					'Orientation',             hThis.CursorbarHandle.Orientation, ...
					'Parent',                  hThis.CursorbarHandle.Parent, ...
					'Position',                hThis.CursorbarHandle.Position, ...
					'SelectionHighlight',      hThis.CursorbarHandle.SelectionHighlight, ...
					'ShowText',                hThis.CursorbarHandle.ShowText, ...
					'Tag',                     hThis.CursorbarHandle.Tag, ...
					'TargetIntersections',     hThis.CursorbarHandle.TargetIntersections, ...
					'TargetMarkerEdgeColor',   hThis.CursorbarHandle.TargetMarkerEdgeColor, ...
					'TargetMarkerFaceColor',   hThis.CursorbarHandle.TargetMarkerFaceColor, ...
					'TargetMarkerSize',        hThis.CursorbarHandle.TargetMarkerSize, ...
					'TargetMarkerStyle',       hThis.CursorbarHandle.TargetMarkerStyle, ...
					'TextDescription',         hThis.CursorbarHandle.TextDescription, ...
					'TopMarker',               hThis.CursorbarHandle.TopMarker, ...
					'UserData',                hThis.CursorbarHandle.UserData, ...
					'Visible',                 hThis.CursorbarHandle.Visible ...
					};
			end
		end
		
	end
	
	% --------------------------------------
	
	methods (Static = true)
		function hThis = loadobj(hThis)
			% LOADOBJ  Restore the Cursorbar listeners on de-serialization.
			
			% create a new cursorbar if the target is valid
			if ~isempty(hThis.Target) && all(isgraphics(hThis.Target)) && ~isempty(hThis.PropertyValues)
				
				% construct a new Cursorbar
				hThat = hThis.PeerContainer;
				if ~isempty(hThat) && ~isempty(hThat.CursorbarHandle)
					% there is a valid Peer: create a Crossbar and set its values
					hThis.CursorbarHandle = drawCrossbar(hThat.CursorbarHandle, hThis.PropertyValues{:});
				else
					% create a new Cursorbar and set its values
					hThis.CursorbarHandle = graphics.Cursorbar(hThis.Target, hThis.PropertyValues{:});
				end
			end
			
		end
	end
	
	%% Auxiliary Methods
	
	methods
		
		function tf = hasCursorbar(hThis,hCursorbar)
			% HASCURSORBAR  Checks if the CursorbarContainer contains the current cursorbar.
			validateattributes(hCursorbar,{'graphics.Cursorbar'},{'scalar'});
			
			% compare
			tf = [hThis.CursorbarHandle]==hCursorbar;
			tf = reshape(tf,size(hThis));
		end
		
	end
		% --------------------------------------
		
		methods (Static)
			function hCursorbars = getCursorbars(hFig)
				% GETCURSORBARS  Get all the cursorbars from the current figure.
				assert(ishghandle(hFig) && strcmp(hFig.Type,'figure'), ...
					'graphics:internal:CursorbarContainer:getCursorbars:notAFigure', ...
					'Input must be a valid figure handle.');
				%
				hContainers = CursorbarContainer.getContainers(hFig);
				if ~isempty(hContainers)
					hCursorbars = [hContainers.CursorbarHandle];
				else
					hCursorbars = graphics.GraphicsPlaceholder.empty;
				end
			end
			
			% --------------------------------------
			
			function hContainers = getContainers(hFig)
				% GETCONTAINERS  Get all the containers from the current figure.
				assert(ishghandle(hFig) && strcmp(hFig.Type,'figure'), ...
					'graphics:internal:CursorbarContainer:getContainers:notAFigure', ...
					'Input must be a valid figure handle.');
				%
				hContainers = getappdata(hFig, graphics.internal.CursorbarContainer.Key);
			end			
	end
	
	%% Protected Methods
	
	methods (Access = {?graphics.Cursorbar, ?graphics.internal.CursorbarContainer})
		
		function setPeer(hThis,hThat)
			% SETPEER  Sets peer container handle.
			
			% set only the handle links
			% Cursorbar is responsible for all the listener mechanisms
			validateattributes(hThis,{'graphics.internal.CursorbarContainer'},{'scalar'});
			validateattributes(hThat,{'graphics.internal.CursorbarContainer'},{'scalar'});
			hThis.PeerContainer = hThat;
			hThat.PeerContainer = hThis;
		end
		
		% --------------------------------------
		
		function removePeer(hThis)
			% REMOVEPEER  Removes peer container handle.
			
			% remove only the handle links
			% Cursorbar is responsible for all the listener mechanisms
			hThis.PeerContainer.PeerContainer = graphics.internal.CursorbarContainer.empty;
			hThis.PeerContainer               = graphics.internal.CursorbarContainer.empty;
		end
		
	end
	
	
end
