% General Plot
function name = runDaq()
    name = 'Daq';
    if ~isValidBaseVar('Collector'); runCollector; end
    evalin('base',[name,'=MyDaq(''collector_handle'',Collector);']);
end

