%data_source=true
%title=Ecdl850Scan

function runNewportTlbScan()

    % Get the unique instance of MyCollector
    C = MyCollector.instance();
    
    name = 'runNewportTlbScan';
    if ~ismember(name, C.running_instruments)
        
        % Create an instrument instance
        App = NewportTlbScan( ...
            'scope_name', 'Dpo4034nano2', ...
            'laser_name', 'ECDL850He3');
        
        % Add instrument to Collector
        addInstrument(C, name, App);
        
        % Display the instrument's name 
        Fig = findFigure(App);
        if ~isempty(Fig)
           Fig.Name = char(name);
        else
           warning('No UIFigure found to assign the name')
        end
        
        % Apply color scheme
        applyLocalColorScheme(Fig);
        
        % Move the app figure to the center of the screen
        centerFigure(Fig);
    else
        disp([name ' is already running'])
        App = getInstrument(C, name);
        
        setFocus(App);
    end
end

