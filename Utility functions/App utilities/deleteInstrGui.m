% Delete Instrument object, clearing the global variable corresponding to 
% gui name and then delete gui itself   
function deleteInstrGui(app)
    %Deletes listeners
    lnames=fieldnames(this.Listeners);
    for i=1:length(lnames)
        delete(this.Listeners.(lnames{i}));
    end
    try
        delete(app.Instr);
    catch
    end
    try
        evalin('base', sprintf('clear(''%s'')', app.name));
    catch
    end
    delete(app)
end

