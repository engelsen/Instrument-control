function hNewDataCursor = createNewDataCursor(hThis,hTarget)
% CREATENEWDATACURSOR  Creates a new data cursor
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2015-2016 The MathWorks, Inc.

% set source
if nargin<2
	hTarget = hThis.Target(1);
end
	
% create a Data Cursor
if isTargetAxes(hThis)
	% target is an axes: create a dummy line handle
	hDummyLineHandle = line(0,0,  'Parent', hThis.GroupHandle, ...
		'Visible','off',           'HandleVisibility','off',  'Clipping','off',...
		'PickableParts','none',    'HitTest','off',           'Interruptible','off');
	hThis.DataCursorDummyTargetHandle = matlab.graphics.chart.primitive.Line(hDummyLineHandle);
	%
	hNewDataCursor   = matlab.graphics.shape.internal.PointDataCursor(hThis.DataCursorDummyTargetHandle);
	
elseif isTargetChart(hThis)
	% target is a chart: create a direct point data cursor
	try % create directly
		hNewDataCursor            = matlab.graphics.shape.internal.PointDataCursor( hTarget );
	catch % probably, not a DataAnnotatable (matlab.graphics.chart.interaction.DataAnnotatable)
		try % create via datacursormode
			hDataCursorMode        = datacursormode();
			hDataTip               = hDataCursorMode.createDatatip( hTarget );
			%
			hNewDataCursor         = hDataTip.Cursor;
			%
			delete(hDataTip);               % it's services are no longer required
			hDataCursorMode.Enable = 'off'; % disable data cursor mode		
		catch % throw error
			error(message('MATLAB:cursorbar:InvalidTarget'));
		end
	end
	
else
	% throw error
	error(message('MATLAB:cursorbar:InvalidTarget'));
end

% delete old handle
hOldDataCursor        = hThis.DataCursorHandle;
delete(hOldDataCursor);

% update old handle
hThis.DataCursorHandle = hNewDataCursor;

