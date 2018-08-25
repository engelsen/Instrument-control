% Return handle to existing Collector or run a new one 
function C = getCollector()
    name = 'Collector';
    if ~isValidBaseVar(name)
        C=MyCollector();
        assignin('base',name,C);
    else
        C=evalin('base',name);
    end
end

