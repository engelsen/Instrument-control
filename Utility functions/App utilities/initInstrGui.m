% Send identification request to instrument and create listeners for 
% instrument events   
function initInstrGui(app)
    % Send identification request to the instrument
    idn(app.Instr);
    % Initiate gui update via listeners
    app.Listeners.PropertyRead=...
        addlistener(app.Instr,'PropertyRead',@(~,~)updateGui(app));
    if ismethod(app,'updatePlot')
        app.Listeners.NewData=...
            addlistener(app.Instr,'NewData',@(~,~)updatePlot(app));
    end
end

