function findInstrumentCallback(app)
    RefVar = MyRefVar('');
    % call the FindInstrumentDlg and wait for it to be closed
    waitfor(FindInstrumentDlg(RefVar));
    if ~isequal(RefVar.value, '')
        % if a new address was chosen, restart the control panel
        startupFcn(app, 'visa', RefVar.value);
    end
end

