% Set values for all the gui elements listed in app.linked_elem_list
% according to the properties of an object (app.Instr by default)
% Instrument property corresponds to the control element having the same
% tag as property name.
% If specified within the control element OutputProcessingFcn or 
% InputPrescaler is applied to the property value first
function updateGui(app, varargin)
    if ~isempty(varargin)
        Obj = varargin{1};
    elseif isprop(app, 'Instr')
        % app.Instr is a MyInstrument object, default choice
        Obj = app.Instr;
    else
        error('Cannot update gui');
    end
    
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        if isprop(Obj, tmpelem.Tag)
            % update the element value
            tmpval = Obj.(tmpelem.Tag);
            % scale the value if the control element has a prescaler
            if isprop(tmpelem, 'OutputProcessingFcn')
                tmpval = tmpelem.OutputProcessingFcn(tmpval);
            elseif isprop(tmpelem, 'InputPrescaler')
                tmpval = tmpval*tmpelem.InputPrescaler;
            end
            tmpelem.Value = tmpval;
        else
        end
    end
end

