%   
function initInstrGui(app,Instrument)
    app.Instr=Instrument;
    % Send identification request to instrument
    idn(app.Instr);
    
    app.Listeners.NewParameter=...
        addlistener(app.Instr,'NewParameter',@(~,~)updateGui(app));
    
    if ismethod(app,'updatePlot')
        app.Listeners.NewData=...
            addlistener(app.Instr,'NewData',@(~,~)updatePlot(app));
    end
    
    createControlLinks(app);
    readPropertyHedged(app.Instr,'all');
end

