% Delete Instrument object, clearing the global variable corresponding to 
% gui name and then delete gui itself   
function deleteInstrGui(app)
    %Deletes listeners
    try
        lnames=fieldnames(app.Listeners);
        for i=1:length(lnames)
            try
                delete(app.Listeners.(lnames{i}));
            catch
                fprintf(['Could not delete the listener to ''%s'' ' ...
                    'event.\n'], lnames{i})
            end
        end
    catch
    end
    
    try
        % Check if the instrument object has appropriate method. This
        % is a safety measure to never delete a file by accident if 
        % app.Instr happens to be a valid file name.
        if ismethod(app.Instr, 'delete')
            delete(app.Instr);
        else
            fprintf(['app.Instr of class ''%s'' does not have ' ...
                '''delete'' method.\n'], class(app.Instr))
        end
    catch
        fprintf('Could not delete the instrument object.\n')
    end
    
    try
        evalin('base', sprintf('clear(''%s'')', app.name));
    catch
    end
    delete(app)
end

