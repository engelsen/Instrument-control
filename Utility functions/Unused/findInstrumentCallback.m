function findInstrumentCallback(app)
    RefVar = MyRefVar('');
    % call the FindInstrumentDlg and wait for it to be closed
    waitfor(InstrumentManager(RefVar));
    if ~isequal(RefVar.value, '')
        % if a new address was chosen, restart the control panel
        app.Instr.Interface = 'constructor';
        app.Instr.address = RefVar.value;
        readPropertyHedged(app.Instr,'all');
        updateGui(app);
    end
end

