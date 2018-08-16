% General Plot
function runDaq()
    name = 'Daq';
    if ~isValidBaseVar('Collector')
        runCollector;
    end
    evalin('base',[name,...
        '=MyDaq(''collector_handle'',Collector,''global_name'',''',name,''');']);
end

