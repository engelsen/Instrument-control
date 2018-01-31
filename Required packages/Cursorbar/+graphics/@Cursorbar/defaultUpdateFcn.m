function defaultUpdateFcn(hThis,~,~)
% DEFAULTUPDATEFCN Default cursorbar UpdateFcn.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Change Log:
%    13 Feb 2015: First version posted on the MathWorks file exchange.
%    14 May 2015: Added logarithmic scale support.

hText = get(hThis,'DisplayHandle');

if strcmp(hThis.ShowText,'off') || strcmp(hThis.Visible,'off')
	if ~isempty(hText)
		delete(hText);
		hThis.DisplayHandle = gobjects(0);
		return
	end
	return
end

% get the locations of the markers
if ~all(isvalid(hThis.TargetMarkerHandle))
	return;
end
xData = get(hThis.TargetMarkerHandle,'XData');
yData = get(hThis.TargetMarkerHandle,'YData');

numIntersections = length(xData);

% get the handles for the text objects, corresponding to each intersection
hAxes = get(hThis,'Parent');

%%%%%%%%%%%%%

AXCOLOR = get(hAxes,'Color');

if ischar(AXCOLOR), AXCOLOR = get(hAxes,'Color'); end

% light colored axes
if sum(AXCOLOR)>1.5
	TEXTCOLOR = [0,0,0]; FACECOLOR = [1 1 238/255]; EDGECOLOR = [.8 .8 .8];
	% dark colored axes (i.e. simulink scopes)
else
	TEXTCOLOR = [.8 .8 .6]; FACECOLOR = 48/255*[1 1 1]; EDGECOLOR = [.8 .8 .6];
end

%%%%%%%%%%%%%

% create text objects if necessary
if isempty(hText)  || any(~ishandle(hText))
	hText = gobjects(numIntersections,1);
	for n = 1:numIntersections
		hText(n) = text(xData(n),yData(n),'',...
			'Parent',hThis.GroupHandle, ... % 'Parent',hAxes,...
			'Color',TEXTCOLOR,...
			'EdgeColor',EDGECOLOR,...
			'BackgroundColor',FACECOLOR,...
			'Visible','off');
	end
	numText = numIntersections;
else
	% if the number of intersections isn't equal to the number of text objects,
	% add/delete them as necessary
	
	set(hText,'Visible','off');
	
	numText = length(hText);
	
	if numText ~= numIntersections
		% unequal number of text objects and intersections
		delete(hText)
		
		hText = gobjects(numIntersections,1);
		
		for n = numIntersections: -1 : 1
			hText(n) = text(xData(n),yData(n),'',...
				'Parent',hThis.GroupHandle, ... % 'Parent',hAxes,...
				'Color',TEXTCOLOR,...
				'EdgeColor',EDGECOLOR,...
				'BackgroundColor',FACECOLOR,...
				'Visible','off');
		end
		numText = numIntersections;
	end
	
end

% now update the text objects

set(hText,'Visible','off','Units','data')

xl = get(hAxes,'XLim');
yl = get(hAxes,'YLim');

xdir = get(hAxes,'XDir');
ydir = get(hAxes,'YDir');

pixperdata = getPixelsPerData(hThis);
pixoffset = 12;

for n = 1:numText
	x = xData(n);
	y = yData(n);
	
	if x >= mean(xl)
		if strcmp(xdir,'normal')
			halign = 'right';
			xoffset = -pixoffset * 1/pixperdata(1);
		else
			halign = 'left';
			xoffset = pixoffset * 1/pixperdata(1);
		end
	else
		if strcmp(xdir,'normal')
			halign = 'left';
			xoffset = pixoffset * 1/pixperdata(1);
		else
			halign = 'right';
			xoffset = -pixoffset * 1/pixperdata(1);
		end
	end
	
	if y >= mean(yl)
		if strcmp(ydir,'normal')
			valign = 'top';
			yoffset = -pixoffset * 1/pixperdata(2);
		else
			valign = 'bottom';
			yoffset = pixoffset * 1/pixperdata(2);
		end
	else
		if strcmp(ydir,'normal')
			valign = 'bottom';
			yoffset = pixoffset * 1/pixperdata(2);
		else
			valign = 'top';
			yoffset = -pixoffset * 1/pixperdata(2);
		end
	end
	
	if ~isempty( hThis.TargetZData )
		[~,ind] = min( hypot(hThis.TargetXData-x, hThis.TargetYData-y) );
		ind = ind(1);
		z   = hThis.TargetZData(ind);
	else
		z = [];
	end
	
	% assert proper scale
	switch [hAxes.XScale '-' hAxes.YScale]
		case 'linear-linear'
			posoffset  = [x+xoffset,    y+yoffset,    0];
		case 'log-linear'
			posoffset  = [x*10^xoffset, y+yoffset,    0];
		case 'linear-log'
			posoffset  = [x+xoffset,    y*10^yoffset, 0];
		case 'log-log'
			posoffset  = [x*10^xoffset, y*10^yoffset, 0];
	end
	
	set(hText(n),'Position',posoffset,...
		'String',makeString(x,y,z,hThis.Orientation,hThis.TextDescription),...
		'HorizontalAlignment',halign,...
		'VerticalAlignment',valign);
end


set(hThis,'DisplayHandle',hText);

set(hText,'Visible','on');

% --------------------------------------
function str = makeString(x,y,z,orient,desc)
% MAKESTRING  Make the text description string
frmt = '%.3g';
switch desc
	case 'short'
		switch orient
			case 'vertical'
				str = ['Y: ' sprintf(frmt,y)];
			case 'horizontal'
				str = ['X: ' sprintf(frmt,x)];
		end
	case 'long'
		if isempty(z)
			str = { ['X: ' sprintf(frmt,x)] , ['Y: ' sprintf(frmt,y)]};
		else
			str = { ['X: ' sprintf(frmt,x)] , ['Y: ' sprintf(frmt,y)] , ['Z: ' sprintf(frmt,z)]};
		end
end
