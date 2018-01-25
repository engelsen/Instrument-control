function findInstrumentCallback(app)
    RefVar = MyRefVar('');
    % call the FindInstrumentDlg and wait for it to be closed
    waitfor(FindInstrumentDlg(RefVar));
    if ~isequal(RefVar.value, '')
        % if a new address was chosen, restart the control panel
        connectDevice(app.Instr, 'constructor', RefVar.value);
        readPropertyHedged(app.Instr,'all');
        updateGui(app);
    end
end

