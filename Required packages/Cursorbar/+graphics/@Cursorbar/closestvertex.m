function [x,y,n] = closestvertex(hThis,pos,orient)
% CLOSESTVERTEX  Return X,Y location of closest Target vertex
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Change Log:
%    13 Feb 2015: First version posted on the MathWorks file exchange.
%    14 May 2015: Added logarithmic scale support.

% input check
if nargin<3 || isempty(orient)
	orient = hThis.Orientation;
end

% initialize
hTarget = hThis.Target;
hAxes   = hThis.Parent;
%
x = [];
y = [];

% don't need to find closest vertex if the Target is an axes
if isTargetAxes(hThis)
	return
end

% get XData and YData
x = hThis.TargetXData;
y = hThis.TargetYData;
n = hThis.TargetNData;

% logarithmic scale requires a logarithmic distance
switch hAxes.XScale
	case 'linear'
		pos_dist(1) = pos(1);
		x_dist      = x;
	case 'log'
		pos_dist(1) = log10(pos(1));
		x_dist      = log10(x);
end
%
switch hAxes.YScale
	case 'linear'
		pos_dist(2) = pos(2);
		y_dist      = y;
	case 'log'
		pos_dist(2) = log10(pos(2));
		y_dist      = log10(y);
end

% translate to pixels
pixperdata = getPixelsPerData(hThis);
%
pos_dist   = pos_dist .* pixperdata;
x_dist     = x_dist    * pixperdata(1);
y_dist     = y_dist    * pixperdata(2);

% determine distance
is_2D_target   = any( strcmp(class(hTarget),graphics.Cursorbar.Permitted2DTargets) ) ...
	|| strcmp(hThis.TargetIntersections,'single');
is_single_target = isscalar(hTarget);

if  is_2D_target
	% determine distance to the closest target
	dist = hypot(pos_dist(1) - x_dist, pos_dist(2) - y_dist);
	
elseif  is_single_target
	% determine distance in a single dimension, dependent on Orientation
	switch orient
		case 'vertical'
			dist = abs(pos_dist(1) - x_dist);
		case 'horizontal'
			dist = abs(pos_dist(2) - y_dist);
	end
else
	% determine distance to the closest target, dependent on Orientation
	distX = abs(pos_dist(1) - x_dist);
	distY = abs(pos_dist(2) - y_dist);
	% punish the secondary distance if the primary distance is too large
	pixoffset = 3; % the error range
	switch orient
		case 'vertical'
			distY(distX-min(distX)>pixoffset) = Inf;
		case 'horizontal'
			distX(distY-min(distY)>pixoffset) = Inf;
	end
	dist = hypot(distX, distY);
end

% get index for minimum distance
[~,ind] = min(dist);

% set output variables
x = x(ind);
y = y(ind);
n = n(ind);
