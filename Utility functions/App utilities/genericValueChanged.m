function genericValueChanged(app, event)
    val = event.Value;
    % scale the value if the control element has a prescaler
    if isprop(event.Source, 'InputPrescaler')
        val = val/event.Source.InputPrescaler;
    end
    
    % Could not find a better solution how to set nested fields than
    % the code below. Due to it's silliness should be efficient, though. 
    ps=regexp(event.Source.Tag,'\.','split');
    switch length(ps)
        case 1
            app.(ps{1})=val;
        case 2
            app.(ps{1}).(ps{2})=val;
        case 3
            app.(ps{1}).(ps{2}).(ps{3})=val;
        case 4
            app.(ps{1}).(ps{2}).(ps{3}).(ps{4})=val;
        case 5
            app.(ps{1}).(ps{2}).(ps{3}).(ps{4}).(ps{5})=val;
        case 6
            app.(ps{1}).(ps{2}).(ps{3}).(ps{4}).(ps{5}).(ps{6})=val;
        otherwise
            error(['References to nested fields beyond 6 levels ',...
                'are not supported presently. You may go to the '...
                'definition of this function to fix.'])
    end
end

