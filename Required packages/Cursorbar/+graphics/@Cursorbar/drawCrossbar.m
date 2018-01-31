function hThat = drawCrossbar(hThis,varargin)
% DRAWCROSSBAR  Draws a linked perpendicular bar.
% 
% See also: graphics.Cursorbar.duplicate, graphics.Cursorbar.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2015-2016 The MathWorks, Inc.

% draw crossbar depending on situation:
if isempty(hThis)
	% empty Cursorbar: return empty array
	hThat = graphics.Cursorbar.empty(size(hThis));
	return
	
elseif ~isscalar(hThis)
	% an array of Cursorbars: recursively draw crossbar to each
	hThat = arrayfun(@(h)drawCrossbar(h,varargin{:}),hThis,'UniformOutput',0);
	hThat = reshape([hThat{:}],size(hThis));
	return
	
elseif ~isvalid(hThis)
	% deleted Cursorbar: create default deleted object
	hThat = graphics.GraphicsPlaceholder;
	delete(hThat);
	return
end

% error check
assert( isempty(hThis.PeerHandle) || ~isvalid(hThis.PeerHandle), ...
	'graphics:Cursorbar:drawCrossbar:existingCrossbar', ...
	'A crossbar to this cursorbar already exists!');

% duplicate
newOrient = theOtherOrientation(hThis);
hThat     = duplicate(hThis,varargin{:},'Orientation',newOrient);

% set peers
hThat.PeerHandle = hThis;
hThis.PeerHandle = hThat;

% reset position
hThis.Position = theOtherPosition(hThis);
hThat.Position = theOtherPosition(hThis);

% set container peers
thisContainer = hThis.Container;
thatContainer = hThat.Container;
%
setPeer( thisContainer, thatContainer );

% link
localLinkCrossbarProps(hThis);
localLinkCrossbarProps(hThat);

end

% --------------------------------------
function l = localLinkCrossbarProps(hCB)
% LOCALLINKCROSSBARPROPS  Set the property linking

% set listeners
l(  1  ) = addlistener(hCB,'Position',   'PostSet', ...
	@(~,~)set(hCB.PeerHandle, 'Position',   hCB.Position));

l(end+1) = addlistener(hCB,'Orientation','PostSet', ...
	@(~,~)set(hCB.PeerHandle, 'Orientation',theOtherOrientation(hCB)));

l(end+1) = addlistener(hCB,'ObjectBeingDestroyed', ...
	@(~,~)localRemoveContainerPeers(hCB));

l(end+1) = addlistener(hCB,'ObjectBeingDestroyed', ...
	@(~,~)delete(hCB.PeerHandle.ExternalListenerHandles));

% store listeners
hCB.ExternalListenerHandles = l;
end

% --------------------------------------
function localRemoveContainerPeers(hThis)
% LOCALREMOVECONTAINERPEERS  Removes the peers from the containers
key = graphics.internal.CursorbarContainer.Key;
%
hFig           = ancestor(hThis.Parent,'figure');
thisContainers = getappdata(hFig,key);
thisCurrent    = thisContainers( thisContainers.hasCursorbar(hThis) );
%
removePeer(thisCurrent);
end

% --------------------------------------
function orient = theOtherOrientation(hCB)
% THEOTHERORIENTATION  Returns the other orientation
switch hCB.Orientation
	case 'horizontal', orient='vertical';
	case 'vertical',   orient='horizontal';
end
end

% --------------------------------------
function pos = theOtherPosition(hCB)
% THEOTHERPOSITION  Returns the other position
pos = hCB.Position;
switch hCB.Orientation
	case 'horizontal', pos(1)=hCB.PeerHandle.Location;
	case 'vertical',   pos(2)=hCB.PeerHandle.Location;
end
end
