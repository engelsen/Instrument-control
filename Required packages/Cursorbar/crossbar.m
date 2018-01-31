function [hCursorbar, hCrossbar] = crossbar(hTarget,varargin)
% CROSSBAR  Creates two perpendicular linked cursorbars.
%
% The cursorbar can be dragged interactively across the axes. If
% attached to a plot, the cursor points are updated as well. The
% cursorbar can be either horizontal or vertical.
%
% The two crossed cursorbars are linked in position. Dragging one will
% update the position of the other to the cursor's location as well. 
%
% Cursorbar requires the new MATLAB graphics system that was
% introduced in R2014b
%
% Usage:
%    crossbar(hTarget)           - Creates two perpendicular linked 
%                                  cursorbars on a target Axes or Chart.
%    crossbar(hTarget, ...)      - Creates two perpendicular linked 
%                                  cursorbars on a target Axes or Chart 
%                                  with additional property-value pairs.
%    hCursorbars = crossbar(...) - Returns the handles to the two
%                                  cursorbars.
%    [hCo,hCross]= crossbar(...) - Returns the handles to the main
%                                  cursorbar and to the crossed one.
% 
% See <a href="matlab:help graphics.Cursorbar">graphics.Cursorbar</a> for the full list of Cursorbar's properties. 
% 
% Example 1: Simple Crossbars
%    x  = linspace(-10,10,101);
%    y  = erf(x/5);
%    %
%    h  = plot(x,y);
%    crossbar(h);
%
% Example 2: Update Properties
%    x  = linspace(-10,10,49);
%    M  = peaks(length(x));
%    %
%    h  = imagesc(x,x,M);
%    [cb,cr] = crossbar(h,'ShowText','off','TargetMarkerStyle','none');
%    %
%    set(cr,'ShowText','on','TargetIntersections','single', ...
%        'TextDescription','long');
%    set([cb; cr], {'CursorLineColor'},{[1.0 0.8 0.8];[1.0 1.0 0.8];});
%    %
%    cb.Position = [-7 3 0];
%
% Example 3: Link Cursorbars
%    t = linspace(0,12*pi,10001)';
%    x = 2*cos(t) + 2*cos(t/6);
%    y = 2*sin(t) - 2*sin(t/6);
%    %
%    h = plot(x,y,'LineWidth',2);
%    axis([-4 4 -4 4]);
%    cb1 = crossbar(h,'CursorLineColor',[1 0 0],'Position',[-1 -1 0], ...
%        'TargetIntersections','single','CursorLineStyle','--');
%    cb2 = crossbar(h,'CursorLineColor',[1 0 1],'Position',[ 1  1 0], ...
%        'TargetIntersections','single','CursorLineStyle','--');
%    %
%    l(1)=addlistener( cb1(1),'Location','PostSet', ...
%        @(~,~)  set ( cb2(1),'Location',cb1(1).Location+2));
%    l(2)=addlistener( cb1(2),'Location','PostSet', ...
%        @(~,~)  set ( cb2(2),'Location',cb1(2).Location+2));
%    l(3)=addlistener( cb2(1),'Location','PostSet', ...
%        @(~,~)  set ( cb1(1),'Location',cb2(1).Location-2));
%    l(4)=addlistener( cb2(2),'Location','PostSet', ...
%        @(~,~)  set ( cb1(2),'Location',cb2(2).Location-2));   
%
% See also: cursorbar, hobjects, graphics.Cursorbar.

% Copyright 2016 The MathWorks, Inc.

% Check MATLAB Graphics system version
if verLessThan('matlab','8.4.0')
	error('crossbar:oldVersion', ...
		'Crossbar requires the new MATLAB graphics system that was introduced in R2014b.');
end

% error check
narginchk (1,Inf);
nargoutchk(0,2);
			
% draw cursorbar
hTemp(1) = graphics.Cursorbar(hTarget,varargin{:});
hTemp(2) = drawCrossbar(hTemp(1),     varargin{:});

% output
switch nargout
	case 0
		% never mind ... 
	case 1
		hCursorbar = hTemp;
	case 2
		hCursorbar = hTemp(1);
		hCrossbar  = hTemp(2);
end

