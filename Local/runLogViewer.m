% Start a logger gui in dummy mode, which allows to browse existing logs

function runLogViewer()
    name = 'LogViewer';
    Lg=MyLogger();
    Lw=GuiLogger(Lg,'dummy_mode',true);
    assignin('base',name,Lw);
end

