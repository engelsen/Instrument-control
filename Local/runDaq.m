% General Plot
function runDaq()
    name = 'Daq';
    C = MyCollector.instance();
    Daq = MyDaq('collector_handle',C,'global_name',name);
    assignin('base',name,Daq);
end

