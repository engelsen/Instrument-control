% Get value of object property named by tag, possibly supporting references
% to sub-objects (in this case tag is 'SubObj1.SubObj2.property').
function val = getPropertyValue(Obj, tag)
    tag_parts = strsplit(tag,'.');
    val = Obj;
    for i=1:length(tag_parts)
        try
            val = val.(tag_parts{i});
        catch
            error('Object does not have %s property', tag_parts{i})
        end
    end
end

