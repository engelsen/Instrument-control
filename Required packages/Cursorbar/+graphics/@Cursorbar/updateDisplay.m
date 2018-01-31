function updateDisplay(hThis,~,~)
% UPDATEDISPLAY  Updates DisplayHandle.
%
% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for 
% MATLAB Graphics and for his contribution of new functionality.

% Copyright 2003-2016 The MathWorks, Inc.

% exit during construction
if hThis.ObjectBeingCreated
	return
end

% update text handles
hText = get(hThis,'DisplayHandle');
%
if strcmp(hThis.ShowText,'off')  || strcmp(hThis.Visible,'off')
    if ~isempty(hText)
        delete(hText);
        hThis.DisplayHandle = gobjects(0);
        return
    end
    return    
end

% update
defaultUpdateFcn(hThis);

if ~isempty(hThis.UpdateFcn)
    hThis.localApplyUpdateFcn(hThis,[]);
end


