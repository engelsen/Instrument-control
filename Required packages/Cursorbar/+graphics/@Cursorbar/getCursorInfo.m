function info = getCursorInfo(hThis)
% GETCURSORINFO Get datacursor info from cursorbar
% 
% See also: graphics.Cursorbar.getMarkerLocations, graphics.Cursorbar.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

info = struct;

hDC = hThis.DataCursorHandle;

info.Position = hDC.Position;
