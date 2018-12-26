% Set values for all the gui elements listed in app.linked_elem_list
% according to the properties they are linked to. 
% The linked property is specified for each element via a subreference 
% structure array stored in elem.UserData.LinkSubs.
% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateLinkedGuiElements(app)
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        try
            % get value using the subreference structure 
            tmpval = subsref(app, tmpelem.UserData.LinkSubs);
            % Apply the output processing function and input prescaler 
            if isprop(tmpelem, 'OutputProcessingFcn')
                tmpval = tmpelem.OutputProcessingFcn(tmpval);
            elseif isprop(tmpelem, 'InputPrescaler')
                tmpval = tmpval*tmpelem.InputPrescaler;
            end
            % Setting value of a matlab app elemen is time consuming, so do
            % this only if the value has actually changed
             if ~isequal(tmpelem.Value,tmpval)
                tmpelem.Value = tmpval;
             end
        catch
            % Try converting the subreference structure to a readable 
            % format and throw a warning
            try
                tag=substruct2str(tmpelem.UserData.LinkSubs);
            catch
                tag='';
            end
            warning(['Could not update the value of element with tag ''%s'' ',...
                'and value ''%s''.'], tag, var2str(tmpval));
        end
    end
end

