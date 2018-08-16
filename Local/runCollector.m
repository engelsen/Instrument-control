function name = runCollector()
    name = 'Collector';
    if ~isValidBaseVar(name)
        evalin('base',[name,'=MyCollector();']);
    else
        warning('Collector is already running');
    end
    
end

