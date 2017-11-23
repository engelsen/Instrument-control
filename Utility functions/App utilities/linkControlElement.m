function linkControlElement(app, elem, prop_tag, varargin)
    p=inputParser();
    addRequired(p,'elem');
    addRequired(p,'prop_tag',@ischar);
    addParameter(p,'input_presc',1,@isnumeric);
    addParameter(p,'create_callback_fcn',@(x)0,@(f)isa(f,'function_handle')); 
    parse(p,elem,prop_tag,varargin{:});

    % The property-control link is established by assigning the tag
    % and adding the control to the list of linked elements
    elem.Tag = prop_tag;
    app.linked_elem_list = [app.linked_elem_list, elem];

    % If the create_callback_fcn is set, assign it to the 
    % ValueChangedFcn which passes the field input to the instument 
    if ~ismember('create_callback_fcn',p.UsingDefaults)
        elem.ValueChangedFcn = feval(p.Results.create_callback_fcn);
    end

    % If the prescaler is indicated, add it to the element as a new property
    if p.Results.input_presc ~= 1
        if isprop(elem, 'InputPrescaler')
            warning('The InputPrescaler propety already exists in the control element');
        else
            addprop(elem,'InputPrescaler');
        end
        elem.InputPrescaler = p.Results.input_presc;
    end
end

