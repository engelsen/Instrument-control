function tf = isTargetChart(hThis,hTarget)
% ISTARGETCHART  Is the Target a permitted chart object
% 
% See also: graphics.Cursorbar.isTargetAxes, graphics.Cursorbar.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.
	
% Copyright 2015-2016 The MathWorks, Inc.

% set the target
if nargin<2
	hTarget = hThis.Target;
end

% return empty if there is no Target
if isempty(hTarget)
    tf = [];
    return
end
%
if ~all(ishandle(hTarget))
	tf = false(size(hTarget));
	return
end

% check
tf = arrayfun(@isChart,hTarget);

function tf = isChart(hTarget)
switch class(hTarget) % fastest comparison with switch
	case graphics.Cursorbar.PermittedChartTargets
		tf = true;
    otherwise
		tf = false;
end
