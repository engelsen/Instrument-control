% Convert structure-based instrument list to a descriptor-based one

function NewInstrList = convertInstrumentListToDescriptor(OldInstrList)
    NewInstrList = MyInstrumentDescriptor.empty();
    
    names = fieldnames(OldInstrList);
    for i = 1:length(names)
        EntrStruct = OldInstrList.(names{i});
        
        NewInstrList(i).name = names{i};
        
        try
            NewInstrList(i).control_class = EntrStruct.control_class;
        catch ME
            warning(ME.message)
        end
        
        try
            NewInstrList(i).title = EntrStruct.menu_title;
        catch ME
            warning(ME.message)
        end
        
        try
            if ~isempty(EntrStruct.interface)
                NewInstrList(i).StartupOpts.interface = EntrStruct.interface;
            end
        catch ME
            warning(ME.message)
        end
        
        try
            if ~isempty(EntrStruct.address)
                NewInstrList(i).StartupOpts.address = EntrStruct.address;
            end
        catch ME
            warning(ME.message)
        end
        
        try
            if ~isempty(EntrStruct.StartupOpts)
                opt_names = fieldnames(EntrStruct.StartupOpts);
                for j=1:lengh(opt_names)
                    NewInstrList(i).StartupOpts.(opt_names{j}) = ...
                        EntrStruct.StartupOpts.(opt_names{j});
                end
            end
        catch
        end
    end
end

