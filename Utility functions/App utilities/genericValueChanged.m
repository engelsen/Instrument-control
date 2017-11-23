function genericValueChanged(app, event)
    val = event.Value;
    % scale the value if the control element has a prescaler
    if isprop(event.Source, 'InputPrescaler')
        val = val/event.Source.InputPrescaler;
    end
    app.Instr.writePropertyHedged(event.Source.Tag, val);
    updateGui(app);
end

