function genericValueChanged(app, event)
    val = event.Value;
    % scale the value if the control element has a prescaler
    if isprop(event.Source, 'InputPrescaler')
        val = val/event.Source.InputPrescaler;
    end
    writePropertyHedged(app.Instr, event.Source.Tag, val);
    updateGui(app);
end

