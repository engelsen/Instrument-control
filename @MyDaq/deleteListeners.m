function deleteListeners(this,obj_name)
%Finds if the object has listeners in the listeners structure
if ismember(obj_name, fieldnames(this.Listeners))
    %Grabs the fieldnames of the object's listeners structure
    names=fieldnames(this.Listeners.(obj_name));
    for i=1:length(names)
        %Deletes the listeners
        if iscell(this.Listeners.(obj_name).(names{i}))
            cellfun(@(x) delete(x), this.Listeners.(obj_name).(names{i}));
        else
            delete(this.Listeners.(obj_name).(names{i}));
        end
        %Removes the field from the structure
        this.Listeners.(obj_name)=...
            rmfield(this.Listeners.(obj_name),names{i});
    end
    %Removes the object's field from the structure
    this.Listeners=rmfield(this.Listeners, obj_name);
end