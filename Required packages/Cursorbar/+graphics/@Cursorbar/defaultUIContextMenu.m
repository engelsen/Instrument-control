function uictxtmenu = defaultUIContextMenu(hThis)
% DEFAULTUICONTEXTMENU  Default Cursorbar UIContextMenu.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% check the figure 
hFig = ancestor(hThis,'figure');
%
if isempty(hFig) || ~ishghandle(hFig)
	% probably, happens during loading process
	% exit to prevent MATLAB from crushing
	uictxtmenu = gobjects(0);
	return
end

% set context menu
uictxtmenu = uicontextmenu('Parent',hFig);
uictxtmenu.Serializable = 'off'; % don't save to file

% define menu properties
menuprops = struct;
menuprops.Parent = uictxtmenu;
menuprops.Serializable = 'off'; % don't save to file

% first menu
menuprops.Label     = 'Show Text';
menuprops.Checked   = hThis.ShowText;
menuprops.Callback  = {@localSetShowText,hThis};
%
u(1) = uimenu(menuprops);
l(1) = event.proplistener(hThis,findprop(hThis,'ShowText'), ...
	'PostSet',@(obj,evd)localGetShowText(u(1),evd,hThis));

% second menu
menuprops.Label     = 'Multiple Intersections';
switch hThis.TargetIntersections
	case 'multiple', menuprops.Checked = 'on';
	case 'single',   menuprops.Checked = 'off';
end
menuprops.Callback  = {@localSetTargetIntersections,hThis};
%
u(2) = uimenu(menuprops);
l(2) = event.proplistener(hThis,findprop(hThis,'TargetIntersections'), ...
	'PostSet',@(obj,evd)localGetTargetIntersections(u(2),evd,hThis));

% third menu
menuprops.Label     = 'Short Description';
switch hThis.TextDescription
	case 'short',  menuprops.Checked = 'on';
	case 'long',   menuprops.Checked = 'off';
end
menuprops.Callback  = {@localSetTextDescription,hThis};
%
u(3) = uimenu(menuprops);
l(3) = event.proplistener(hThis,findprop(hThis,'TextDescription'), ...
	'PostSet',@(obj,evd)localGetTextDescription(u(3),evd,hThis));

% store listeners
hThis.SelfListenerHandles = [hThis.SelfListenerHandles, l];

%% Subfunctions

function localGetShowText(hMenu,~,hThis)
% LOCALGETSHOWTEXT Get ShowText property.
switch hThis.ShowText
	case 'on',  hMenu.Checked = 'on';
	case 'off', hMenu.Checked = 'off';
end

function localSetShowText(hMenu,~,hThis)
% LOCALSETSHOWTEXT SetShowText Property
switch get(hMenu,'Checked')
	case 'on'
		set(hMenu,'Checked','off')
		set(hThis,'ShowText','off')
	case 'off'
		set(hMenu,'Checked','on')
		set(hThis,'ShowText','on')
end

% --------------------------------------

function localGetTargetIntersections(hMenu,~,hThis)
% LOCALGETTARGETINTERSECTIONS Get TargetIntersections Property
switch hThis.TargetIntersections
	case 'multiple',  hMenu.Checked = 'on';
	case 'single',    hMenu.Checked = 'off';
end

function localSetTargetIntersections(hMenu,~,hThis)
% LOCALSETTARGETINTERSECTIONS Set TargetIntersections Property
switch get(hMenu,'Checked')
	case 'on'
		set(hMenu,'Checked','off')
		set(hThis,'TargetIntersections','single')
	case 'off'
		set(hMenu,'Checked','on')
		set(hThis,'TargetIntersections','multiple')
end

% --------------------------------------

function localGetTextDescription(hMenu,~,hThis)
% LOCALGETTEXTDESCRIPTION Get TextDescription Property
switch hThis.TextDescription
	case 'short',  hMenu.Checked = 'on';
	case 'long',   hMenu.Checked = 'off';
end

function localSetTextDescription(hMenu,~,hThis)
% LOCALSETTEXTDESCRIPTION Set TextDescription Property
switch get(hMenu,'Checked')
	case 'on'
		set(hMenu,'Checked','off')
		set(hThis,'TextDescription','long')
	case 'off'
		set(hMenu,'Checked','on')
		set(hThis,'TextDescription','short')
end
