function move(hThis,dir)
% MOVE Move the data cursor and update cursorbar
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Update cursor based on direction 
moveDataCursor(hThis.DataCursorHandle,hThis,hThis.DataCursorHandle,dir); 

pos = get(hThis.DataCursorHandle,'Position');
set(hThis,'Position',pos);

% throw event indicating that the cursorbar was updated
notify(hThis,'UpdateCursorBar');
