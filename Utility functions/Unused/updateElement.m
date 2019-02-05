% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateElement(elem, EventData)
    try
        % Get value of the property that generated event
        tmpval = EventData.AffectedObject.(EventData.Source.Name); 
        % scale the value if the control element has a prescaler
        if isprop(elem, 'OutputProcessingFcn')
            tmpval = elem.OutputProcessingFcn(tmpval);
        elseif isprop(elem, 'InputPrescaler')
            tmpval = tmpval*elem.InputPrescaler;
        end
        % Setting value of a matlab app elemen is time consuming, so do
        % this only if the value has actually changed
         if ~isequal(elem.Value,tmpval)
            elem.Value = tmpval;
         end
    catch
        warning(['Could not update the value of element with tag ''%s'' ',...
            'and value ''%s''. The element will be disabled.'],...
            elem.Tag,var2str(tmpval));
        elem.Enable='off';
    end
end