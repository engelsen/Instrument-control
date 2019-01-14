
function updateLinkedElement(app, elem)
    try
        % get value using the subreference structure 
        val = subsref(app, elem.UserData.LinkSubs);
        % Apply the output processing function or input prescaler 
        if isfield(elem.UserData, 'OutputProcessingFcn')
            val = elem.UserData.OutputProcessingFcn(val);
        elseif isfield(elem.UserData, 'InputPrescaler')
            val = val*elem.UserData.InputPrescaler;
        end
        % Get the gui property to be updated. The default is Value.
        if isfield(elem.UserData, 'elem_prop')
            elem_prop=elem.UserData.elem_prop;
        else
            elem_prop='Value';
        end
        % Setting value of a matlab app elemen is time consuming, so do
        % this only if the value has actually changed
         if ~isequal(elem.(elem_prop),val)
            elem.(elem_prop) = val;
         end
    catch
        % Try converting the subreference structure to a readable 
        % format and throw a warning
        try
            tag=substruct2str(elem.UserData.LinkSubs);
        catch
            tag='';
        end
        warning(['Could not update the value of element with tag ''%s'' ',...
            'and value ''%s''.'], tag, var2str(val));
    end
end

