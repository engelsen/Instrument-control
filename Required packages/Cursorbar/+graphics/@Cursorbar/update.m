function update(hThis,~,~,varargin) 
% UPDATE Update cursorbar position and string
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.


% Exit during construction
if hThis.ObjectBeingCreated
	return
end

% Check input
movecb = true;
if nargin >= 4 && ischar(varargin{1}) && strcmp(varargin{1},'-nomove')
    movecb = false;
end
    
% Create new data cursor
if isvalid(hThis.DataCursorHandle)
    hNewDataCursor = hThis.DataCursorHandle;
else
    hNewDataCursor = createNewDataCursor(hThis);
end

% Update cursor based on target
if movecb
	updateDataCursor(hThis,hNewDataCursor); 
	hNewDataCursor = hThis.DataCursorHandle; % in the case it has changed
end
    
% Update cursorbar based on cursor
updatePosition(hThis,hNewDataCursor);

% Update markers
updateMarkers(hThis);

% Send event indicating that the cursorbar was updated
notify(hThis,'UpdateCursorBar');
