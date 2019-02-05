% Set values for all the gui elements listed in app.linked_elem_list
% according to the properties they are linked to. 
% The linked property is specified for each element via a subreference 
% structure array stored in elem.UserData.LinkSubs.
% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateLinkedGuiElements(app)
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        updateLinkedElement(app, tmpelem);
    end
end

