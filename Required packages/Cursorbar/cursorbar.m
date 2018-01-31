function hCursorbar = cursorbar(hTarget,varargin)
% CURSORBAR  Creates a cursor line attached to an axes or lines.
%
% The cursorbar can be dragged interactively across the axes. If
% attached to a plot, the cursor points are updated as well. The
% cursorbar can be either horizontal or vertical.
%
% Cursorbar requires the new MATLAB graphics system that was
% introduced in R2014b
%
% Usage:
%    cursorbar(hTarget)           - Creates a cursorbar on a target Axes
%                                   or Chart.
%    cursorbar(hTarget, ...)      - Creates a cursorbar on a target Axes
%                                   or Chart with additional property-
%                                   value pairs.
%    hCursorbar = cursorbar(...)  - Returns the handle to the Cursorbar.
% 
% See <a href="matlab:help graphics.Cursorbar">graphics.Cursorbar</a> for the full list of Cursorbar's properties. 
% 
% Example 1: Simple Cursorbar
%    x  = linspace(0,20,101);
%    y  = sin(x);
%    %
%    h  = plot(x,y);
%    cursorbar(h);
%
% Example 2: Target Axes
%    x = linspace(-2,2,101)';
%    Y = [sin(x), 1-x.^2/2, erf(x), ones(size(x))];
%    %
%    area(x,abs(Y));
%    cursorbar(gca,'CursorLineColor',[0.02 0.75 0.27]);
%    set(gca,'Color','r')
%
% Example 3: Stem Plot
%    x  = 1:19;
%    Y  = interp1(1:5,magic(5),linspace(1,5,19),'pchip');
%    %
%    h  = stem(x,Y);
%    cb = cursorbar(h);
%    cb.TargetMarkerStyle = 'x';
%
% Example 4: Logarithmic YScale
%    x  = linspace(0,4,41)';
%    Y  = [exp(2*x)/4,  exp(x/10)+1/160*exp(3*x), x.^2+1];
%    %
%    h  = stairs(x,Y,'LineWidth',2);
%    %
%    ax = gca;
%    ax.YScale  = 'log';
%    ax.YLim(2) = 1000;
%    grid on;
%    %
%    cursorbar(h,'Location',2.7)
%
% Example 5: Crossbar
%    x  = linspace(-10,10,49);
%    M  = peaks(length(x));
%    %
%    h  = imagesc(x,x,M);
%    cb = cursorbar(h,'ShowText','off','TargetMarkerStyle','none');
%    %
%    cr = drawCrossbar(cb);
%    set(cr,'ShowText','on','TargetIntersections','single', ...
%        'TextDescription','long');
%    set([cb; cr], {'CursorLineColor'},{[1.0 0.8 0.8];[1.0 1.0 0.8];});
%    %
%    cb.Position = [-7 3 0];
%
% Example 6: Preallocation
%    x = linspace(-3,3,101);
%    y = exp(-x.^2/2);
%    %
%    h = plot(x,y);
%    for i=5:-1:1,
%        cb(i) = cursorbar( h, 'Location',i-3, ...
%            'CursorLineColor',[(1-i/5) 0 i/5]);
%    end
%
% Example 7: Listeners
%    t = linspace(0,32*pi,10001)';
%    x = 2*cos(t) + 2*cos(t/16);
%    y = 2*sin(t) - 2*sin(t/16);
%    %
%    ax= axes('XLim',[-4 4],'YLim',[-4 4],'NextPlot','add');
%    h = plot(x,y,'Color',[0.929 0.694 0.125]);
%    %
%    for i=5:-1:1,
%        cb(i) = cursorbar( h, 'Location',i-3, 'ShowText','off', ...
%    		    'CursorLineColor',[(1-i/5) i/5  0]);
%    end
%    %
%    % add listeners
%    for i=1:5,
%        j = mod(i,5)+1;
%        addlistener ( cb(i),'Location','PostSet', ...
%            @(~,~)set(cb(j),'Location',cb(i).Location+j-i));
%    end
%    %
%    addlistener(cb,'BeginDrag',@(~,~)set(ax,'Color',[.9 .8 .9]));
%    addlistener(cb,'EndDrag'  ,@(~,~)set(ax,'Color','w'));
%    addlistener(cb,'UpdateCursorBar', ...
%        @(~,~)set(h,'LineWidth',abs(cb(3).Location)+1));
%    
% Example 8: Save and Load
%    % draw Cursorbars
%    x = linspace(-4,4,101);
%    y = cos(x);
%    h = plot(x,y);
%    %
%    cb(1) = cursorbar(h,'Location',2.50,'CursorLineColor',[1 0 0]);
%    cb(2) = cursorbar(h,'Location',-.25,'CursorLineColor',[0 1 0],...
%        'Orientation','horizontal');
%    cb(3) = drawCrossbar(cb(2));
%    %
%    % save and load
%    tempname = 'temp_cb.fig';
%    savefig(gcf,tempname);
%    %
%    open(tempname);
%    
% Example 9: Marker Styles
%    % create line plot
%    x = linspace(0,14,201);
%    y = sin(2*pi*x/3);
%    %
%    h = plot(x,y,':k','LineWidth',2);
%    ylim([-1.2 1.2]);
%    %
%    % define colors
%    topMarkers    = 'x+*o.sdv^><ph';  %    top marker styles
%    bottomMarkers = 'x+*o.sd^v<>hp';  % bottom marker styles
%    targetMarkers = '+xo*.dsddddhp';  % target marker styles
%    lineColor     = lines(13);        % cursorbar colors
%    %
%    % create cursorbars
%    for i=1:13
%        c(i) = graphics.Cursorbar(h,'Location',i);
%        %
%        c(i).TopMarker               = topMarkers(i);
%        c(i).BottomMarker            = bottomMarkers(i);
%        c(i).TargetMarkerStyle       = targetMarkers(i);
%        %
%        c(i).CursorLineColor         = lineColor(i,:);
%        c(i).TargetMarkerEdgeColor   = 1-lineColor(i,:);
%        %
%        c(i).TopHandle.MarkerSize    = 12;
%        c(i).BottomHandle.MarkerSize = 12;
%    end
%    %
%    set(c,'ShowText','off','TargetMarkerSize',12,'TargetMarkerFaceColor','w');
%
% See also: crossbar, hobjects, graphics.Cursorbar.

% Copyright 2016 The MathWorks, Inc.

% Check MATLAB Graphics system version
if verLessThan('matlab','8.4.0')
	error('cursorbar:oldVersion', ...
		'Cursorbar requires the new MATLAB graphics system that was introduced in R2014b.');
end

% error check
narginchk (1,Inf);
nargoutchk(0,1);
		
% draw cursorbar
if nargout==0
	graphics.Cursorbar(hTarget,varargin{:});
else
	hCursorbar = graphics.Cursorbar(hTarget,varargin{:});
end

