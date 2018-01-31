function tf = isTargetAxes(hThis)
% ISTARGETAXES  Is the Target an axes
% 
% See also: graphics.Cursorbar.isTargetChart, graphics.Cursorbar.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

tf = false;

% return empty if there is no Target
if isempty(hThis.Target)
    tf = [];
    return
end

if (length(hThis.Target) == 1) && ishandle(hThis.Target) && isa(hThis.Target,'matlab.graphics.axis.Axes')
    tf = true;
end
