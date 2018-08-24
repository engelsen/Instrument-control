function genericValueChanged(app, event)
    val = event.Value;
    % scale the value if the control element has a prescaler
    if isprop(event.Source, 'InputPrescaler')
        val = val/event.Source.InputPrescaler;
    end
    prop = sscanf(event.Source.Tag, 'Instr.%s');
    writePropertyHedged(app.Instr, prop, val);
end

