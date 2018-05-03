%Finds if the obj or struct contains a MyInstrument class and returns the handle
function instr_handle=findMyInstrument(obj)
    props=properties(obj);
    
    if isempty(props) && isstruct(obj)
        props=fieldnames(obj);
    elseif isempty(props)
        warning('Invalid data type. Could not search for MyInstrument')
        return
    end
    
    ind=cellfun(@(x) isa(obj.(x),'MyInstrument'), props);
    if any(ind)
        instr_handle=obj.(props{ind}); 
    else
        warning('No MyInstrument found');
    end
end