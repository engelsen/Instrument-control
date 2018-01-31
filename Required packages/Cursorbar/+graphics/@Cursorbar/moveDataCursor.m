function moveDataCursor(hThis,hDataCursor,direc)
% MOVEDATACURSOR  Move the data cursor
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Change Log:
%    13 Feb 2015: First version posted on the MathWorks file exchange.
%    14 May 2015: Added logarithmic scale support.

pos = hDataCursor.Position;

hTarget = hThis.Target;
hAxes = get(hThis,'Parent');

xdir = get(hAxes,'XDir');
ydir = get(hAxes,'YDir');

if all(isTargetChart(hThis))
	% determine next vertex
	x = pos(1);
	y = pos(2);
	
	XData = hThis.TargetXData;
	YData = hThis.TargetYData;
	
	switch hThis.Orientation
		case 'vertical'
			% determine what the next possible X value is
			switch xdir
				case 'normal'
					switch direc
						case 'right'
							% find next largest x value
							ind = localNextIndex(x,XData,'greater');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						case 'left'
							% find next smallest x value
							ind = localNextIndex(x,XData,'less');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						otherwise
							% do nothing
					end
				case 'reverse'
					switch direc
						case 'right'
							% find next smallest x value
							ind = localNextIndex(x,XData,'less');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						case 'left'
							% find next largest x value
							ind = localNextIndex(x,XData,'greater');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						otherwise
							% do nothing
					end
			end
		case 'horizontal'
			% determine what the next possible Y value is
			switch ydir
				case 'normal'
					switch direc
						case 'up'
							% find next largest x value
							ind = localNextIndex(y,YData,'greater');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						case 'down'
							% find next smallest x value
							ind = localNextIndex(y,YData,'less');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						otherwise
							% do nothing
					end
				case 'reverse'
					switch direc
						case 'up'
							% find next smallest x value
							ind = localNextIndex(y,YData,'less');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						case 'down'
							% find next largest x value
							ind = localNextIndex(y,YData,'greater');
							pos(1) = XData(ind);
							pos(2) = YData(ind);
						otherwise
							% do nothing
					end
			end
	end
elseif numel(hTarget) == 1 && isa(hTarget,'matlab.graphics.axis.Axes')
	pixperdata = getPixelsPerData(hThis);
	switch hThis.Orientation
		case 'vertical'
			switch xdir
				case 'normal'
					switch direc
						case 'right'
							xoffset = + 1/pixperdata(1);
						case 'left'
							xoffset = - 1/pixperdata(1);
						otherwise
							% do nothing
					end
				case 'reverse'
					switch direc
						case 'right'
							xoffset = - 1/pixperdata(1);
						case 'left'
							xoffset = + 1/pixperdata(1);
						otherwise
							% do nothing
					end
			end
		case 'horizontal'
			switch ydir
				case 'normal'
					switch direc
						case 'up'
							yoffset = + 1/pixperdata(2);
						case 'down'
							yoffset = - 1/pixperdata(2);
						otherwise
							% do nothing
					end
				case 'reverse'
					switch direc
						case 'up'
							yoffset = - 1/pixperdata(2);
						case 'down'
							yoffset = + 1/pixperdata(2);
						otherwise
							% do nothing
					end
			end
		otherwise
			% not vertical or horizontal
	end
	
	% assert proper scale
	x = pos(1);
	y = pos(2);
	%
	switch [hAxes.XScale '-' hAxes.YScale]
		case 'linear-linear'
			pos = [x+xoffset,    y+yoffset,    0];
		case 'log-linear'
			pos = [x*10^xoffset, y+yoffset,    0];
		case 'linear-log'
			pos = [x+xoffset,    y*10^yoffset, 0];
		case 'log-log'
			pos = [x*10^xoffset, y*10^yoffset, 0];
	end
		
else
	% not lines or an axes
end


hDataCursor.Position = pos;

function ind = localNextIndex(d,Data,cmp)

switch cmp
	case 'greater'
		ind = find(Data > d);
		if isempty(ind)
			ind = length(Data);
			return
		end
		ind = min(ind);
	case 'less'
		ind = find(Data < d);
		if isempty(ind)
			ind = 1;
			return
		end
		ind = max(ind);
end
