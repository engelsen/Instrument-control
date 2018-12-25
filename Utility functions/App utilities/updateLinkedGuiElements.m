% Set values for all the gui elements listed in app.linked_elem_list
% according to the properties of an object 
% Instrument property corresponds to the control element having the same
% tag as property name, may be a filed of structure or a property of class
% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateLinkedGuiElements(app)
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        try
            % update the element value based on elem.UserData.LinkSubs 
            tmpval = subsref(app, tmpelem.UserData.LinkSubs);
            % scale the value if the control element has a prescaler
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

