function findInstrumentCallback(app)
    RefVar = MyRefVar('');
    FindInstrumentDlg(RefVar);
    if ~isequal(RefVar.value, '')
        % if a new address was chosen, restrart panel
        startupFcn(app, 'visa', RefVar.value);
    end
end

