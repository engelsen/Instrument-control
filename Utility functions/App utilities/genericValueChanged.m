function genericValueChanged(app, event)
    val = event.Value;
    % scale the value if the control element has a prescaler
    if isprop(event.Source, 'InputPrescaler')
        val = val/event.Source.InputPrescaler;
    end
    
    assert(isfield(event.Source.UserData,'LinkSubs'),...
        '''LinkSubs'' structure is missing from a linked element.')
    
    app=subsasgn(app, event.Source.UserData.LinkSubs, val); %#ok<NASGU>
end

