% Convert structure S to the list of fieldname-value pairs

function nv = struct2namevalue(S)
    fns=fieldnames(S);
    vals=struct2cell(S);
    nv=cell(1,2*length(fns));
    for i=1:length(fns)
        nv{2*i-1}=fns{i};
        nv{2*i}=vals{i};
    end
end

