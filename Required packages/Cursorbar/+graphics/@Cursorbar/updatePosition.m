function updatePosition(hThis,hNewDataCursor)
% UPDATEPOSITION  Update cursorbar position based on data cursor
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Set parameters
pos = hNewDataCursor.Position;
hAxes = hThis.Parent;
ok = false;

% See if the cursor position is empty or outside the axis limits
xlm = get(hAxes,'XLim');
ylm = get(hAxes,'YLim');
zlm = get(hAxes,'ZLim');
%
if ~isempty(pos) && ...
        (pos(1) >= min([xlm Inf])) && (pos(1) <= max([xlm -Inf])) && ...
        (pos(2) >= min([ylm Inf])) && (pos(2) <= max([ylm -Inf]))
    if length(pos) > 2
        if pos(3) >= min([zlm Inf]) && pos(3) <= max([zlm -Inf])
            ok =true;
        end
	 else
        pos(3) = 0;
        ok = true;
    end
end

% Update DataCursorHandle and Position
if ok
    hThis.DataCursorHandle = hNewDataCursor;
    hThis.Position = pos;
end
