% Set values for all the gui elements listed in app.linked_elem_list
% according to the properties of an object (app.Instr by default)
% Instrument property corresponds to the control element having the same
% tag as property name.
% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateGui(app, varargin)
    if ~isempty(varargin)
        SrcObj = varargin{1};
    elseif isprop(app, 'Instr')
        % app.Instr is a MyInstrument object, default choice
        SrcObj = app.Instr;
    else
        error('Source object is not provided for gui update');
    end
    
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        try
            % update the element value based on Obj.(tag), 
            % where tag can contain a reference to sub-objects
            tmpval = getPropertyValue(SrcObj, tmpelem.Tag);
            % scale the value if the control element has a prescaler
            if isprop(tmpelem, 'OutputProcessingFcn')
                tmpval = tmpelem.OutputProcessingFcn(tmpval);
            elseif isprop(tmpelem, 'InputPrescaler')
                tmpval = tmpval*tmpelem.InputPrescaler;
            end
            tmpelem.Value = tmpval;
        catch
        end
    end
end

