function updateMarkers(hThis)
% UPDATEMARKERS Updates data markers.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% exit during construction
if hThis.ObjectBeingCreated
	return
end

% get line handles
hTarget = hThis.Target;

% get current position
pos = get(hThis,'Position');
if isempty(pos), return; end % probably, at startup

% determine which vertices will be intersected
switch hThis.TargetIntersections
	case 'multiple' % find all intersection based on the Orientation
		switch hThis.Orientation
			case 'vertical'
				ind = find(hThis.TargetXData == pos(1));             % find only the identical positions
				if isempty(ind)
					[~,ind] = min( abs(hThis.TargetXData - pos(1)) ); % find the closest ones
				end
			case 'horizontal'
				ind = find(hThis.TargetYData == pos(2));             % find only the identical positions
				if isempty(ind)
					[~,ind] = min( abs(hThis.TargetYData - pos(2)) ); % find the closest ones
				end
		end
	case 'single' % just the closest ones
		[~,ind] = min( hypot(hThis.TargetXData-pos(1), hThis.TargetYData-pos(2)) );
		if ~isempty(ind)
			ind = ind(1);
		end
end

% set the target markers
if all(isvalid(hThis.TargetMarkerHandle))
	if all(isvalid(hTarget)) && ~isa(hTarget,'matlab.graphics.axis.Axes')
		set(hThis.TargetMarkerHandle,'Visible','on',...
			'XData',hThis.TargetXData(ind),...
			'YData',hThis.TargetYData(ind));
	else
		%
		set(hThis.TargetMarkerHandle,'Visible','off',...
			'XData',[],...
			'YData',[]);
	end
end
