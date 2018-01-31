function pixperdata = getPixelsPerData(hThis)
% GETPIXELSPERDATA  Return pixel-per-data ratio
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% Change Log:
%    13 Feb 2015: First version posted on the MathWorks file exchange.
%    14 May 2015: Added logarithmic scale support.

hAxes = get(hThis,'Parent');

% get axes' limits
xl = get(hAxes,'XLim');
yl = get(hAxes,'YLim');

% get Axes' pixel position
pixpos = getpixelposition(hAxes);

% assert proper scale
switch [hAxes.XScale '-' hAxes.YScale]
	case 'linear-linear'
		pixperdata = [ pixpos(3) /      (xl(2)-xl(1)),   pixpos(4) /      (yl(2)-yl(1))];
	case 'log-linear'
		pixperdata = [ pixpos(3) / log10(xl(2)/xl(1)),   pixpos(4) /      (yl(2)-yl(1))];
	case 'linear-log'
		pixperdata = [ pixpos(3) /      (xl(2)-xl(1)),   pixpos(4) / log10(yl(2)/yl(1))];
	case 'log-log'
		pixperdata = [ pixpos(3) / log10(xl(2)/xl(1)),   pixpos(4) / log10(yl(2)/yl(1))];
end
