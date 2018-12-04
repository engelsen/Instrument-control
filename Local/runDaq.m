% General Plot
function runDaq()
    name = 'Daq';
    C = getCollector();
    Daq = MyDaq('collector_handle',C,'global_name',name);
    assignin('base',name,Daq);
end

