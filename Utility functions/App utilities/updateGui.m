% update all the linked control elements according to their counterpart properties
function updateGui(app)
% Instrument is a MyInstrument object
    for i=1:length(app.linked_elem_list)
        tmpelem = app.linked_elem_list(i);
        if isprop(app.Instr, tmpelem.Tag)
            tmpval = app.Instr.(tmpelem.Tag);
            % scale the value if the control element has a prescaler
            if isprop(tmpelem, 'OutputProcessingFcn')
                tmpval = tmpelem.OutputProcessingFcn(tmpval);
            elseif isprop(tmpelem, 'InputPrescaler')
                tmpval = tmpval*tmpelem.InputPrescaler;
            end
            tmpelem.Value = tmpval;
        end
    end
end

