% This function replaces the reference path for a linked gui element.
% It mainly surves the purpose of decoupling the high-level operation 
% of reassignment from the impementation of linking mechanism.

function relinkGuiElement(elem, new_prop_tag)
    % Make sure the property tag starts with a dot and convert to
    % subreference structure
    if new_prop_tag(1)~='.'
        PropSubref=str2substruct(['.',new_prop_tag]);
    else
        PropSubref=str2substruct(new_prop_tag);
    end
    % Assign new subreference structure
    elem.UserData.LinkSubs = PropSubref;
end

