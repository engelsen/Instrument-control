function [x,y] = getMarkerLocations(hThis)
% GETMARKERLOCATIONS Return x,y position of the Cursorbar's intersection markers
% 
% See also: graphics.Cursorbar.getCursorInfo, graphics.Cursorbar.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

hMarker = hThis.TargetMarkerHandle;

x = get(hMarker,'XData');
y = get(hMarker,'YData');
