function updateDataCursor(hThis,hNewDataCursor,~)
%UPDATEDATACURSOR Updates DataCursor's position.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

hAxes = get(hThis,'Parent');
cp = get(hAxes,'CurrentPoint');
pos = [cp(1,1) cp(1,2) 0];
hTarget = hThis.Target;

if isTargetAxes(hThis)
    % axes: ignore interpolation, just use the axes' CurrentPoint
    hNewDataCursor.DataSource.XData = pos(1);
    hNewDataCursor.DataSource.YData = pos(2);
	 
else
	% put the DataCursor in a correct place
    [x,y,n] = closestvertex(hThis,pos);
	if ~isscalar(hTarget)
		if isa(hTarget,'matlab.graphics.chart.interaction.DataAnnotatable')
			hNewDataCursor.DataSource = hTarget(n);
		else
			hNewDataCursor = createNewDataCursor(hThis,hTarget(n));
		end
	end
	
	% update the DataCursor
	if strcmp(hAxes.Parent.Type,'figure')
		% update directly
		hNewDataCursor.Position = [x y 0];
	else
		% if the parent is not a figure (e.g., panel), the position of the 
		% DataCursor is not rendered correctly; thus, a change of parents
		% is mandatory
		axesPar = hAxes.Parent;
		hAxes.Parent = ancestor(hAxes,'figure');
		hNewDataCursor.Position = [x y 0];
		hAxes.Parent = axesPar;
	end
end
