function genericValueChanged(app, event)
    val = event.Value;
    
    % Apply input processing function or prescaler if exist
    if isfield(event.Source.UserData, 'InputProcessingFcn')
        val = event.Source.UserData.InputProcessingFcn(val);
    elseif isfield(event.Source.UserData, 'InputPrescaler')
        val = val/event.Source.UserData.InputPrescaler;
    end
    
    assert(isfield(event.Source.UserData,'LinkSubs'),...
        '''LinkSubs'' structure is missing from a linked element.')
    
    app=subsasgn(app, event.Source.UserData.LinkSubs, val); %#ok<NASGU>
end

