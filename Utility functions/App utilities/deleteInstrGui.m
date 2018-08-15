% Delete Instrument object, clearing the global variable corresponding to 
% gui name and then delete gui itself   
function deleteInstrGui(app)    
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

