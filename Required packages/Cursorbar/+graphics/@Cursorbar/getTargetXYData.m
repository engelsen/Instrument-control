function [x,y,z,n] = getTargetXYData(hThis,orient)
% GETTARGETXYDATA Create vectors of Target XData and YData
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% set inputs
if nargin<2 || isempty(orient)
	orient = hThis.Orientation;
end
hTarget = hThis.Target;

x = [];
y = [];
z = [];
n = [];

% set data
if isTargetAxes(hThis)
	 return
else
	if isa(hTarget,'matlab.graphics.chart.primitive.Histogram')
		xDataName = 'BinEdges';
		yDataName = 'Values';
	else
		xDataName = 'XData';
		yDataName = 'YData';
	end
	%
	if numel(hTarget) == 1
		xData = {get(hTarget,xDataName)};
		yData = {get(hTarget,yDataName)};
	else % should all be lines
		xData = get(hTarget, xDataName);
		yData = get(hTarget, yDataName);
	end
	%
	if isa(hTarget,'matlab.graphics.chart.primitive.Histogram')
		xData = cellfun(@(x)x(2:end)-diff(x)/2, xData,      'UniformOutput', 0); % transform to BinCenters
	end
end

% check if CData exists
try
	try 
		zData = {hTarget.ZData};
	catch
		zData = {hTarget.CData};
	end
	isZData  = sum(cellfun('prodofsize',zData))>0;
	%
	if isZData && ~isequal( cellfun(@numel,xData), cellfun(@numel,zData) )
		[xData, yData] = cellfun( @meshgrid,  xData, yData, 'UniformOutput', 0);
		xData          = cellfun( @(a)a(:).', xData,        'UniformOutput', 0);
		yData          = cellfun( @(a)a(:).', yData,        'UniformOutput', 0);
	end
catch % never mind ...
	zData = {};
	isZData = false;
end

% determine how many vertices each line has
numLineVertices = cellfun('prodofsize',xData);

% determine the total number of vertices
numAllVertices = sum(numLineVertices);

% create vectors to hold locations for all vertices
xVertices = zeros(1,numAllVertices);
yVertices = zeros(1,numAllVertices);
zVertices = zeros(1,numAllVertices);
nVertices = zeros(1,numAllVertices);

% initialize variable to hold the last entered data position
lastDataPos = 0;
for n = 1:length(hTarget)
    lenData = length(xData{n});    
    xVertices(lastDataPos+1:lastDataPos+lenData) = xData{n};
    yVertices(lastDataPos+1:lastDataPos+lenData) = yData{n};
	 if isZData
		 zVertices(lastDataPos+1:lastDataPos+lenData) = zData{n};
	 end
    nVertices(lastDataPos+1:lastDataPos+lenData) = n;
    lastDataPos = lastDataPos + lenData;    
end

% sort the Target's XData and YData based on the Orientation
switch orient
    case 'vertical'
        [x,ind] = sort(xVertices);
        y = yVertices(ind);        
    case 'horizontal'
        [y,ind] = sort(yVertices);
        x = xVertices(ind);
end

if isZData
	z = zVertices(ind);
end

n = nVertices(ind);
