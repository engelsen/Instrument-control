classdef MyCollector < MySingleton
    
    properties (SetObservable)
        
        % Measurement session name
        session_name    char
    end

    properties (GetAccess = public, SetAccess = private, SetObservable)
        
        % Structure accomodating handles of instrument objects 
        InstrList = struct()
        
        % Structure accomodating handles of apps which contain user
        % interface elements (excluding instrument GUIs)
        AppList = struct()
    end
    
    properties (Access = private)
        
        % Metadata indicating the state of Collector
        Metadata    MyMetadata
    end
    
    properties (Dependent)
        running_instruments
        running_apps
    end
    
    methods (Access = private)
        
        % The constructor of a singleton class must be private
        function this = MyCollector()
            disp(['Creating a new instance of ' class(this)])
            this.session_name = 'Measurement session';
        end
    end
    
    methods (Access = public)
        function delete(this)
            
            % Delete listeners 
            fn = fieldnames(this.InstrList);
            for i = 1:length(fn)
                try 
                    delete(this.InstrList.(fn{i}).Listeners)
                catch ME
                    warning(['Collector listeners for ' fn{i} ...
                        ' could not be deleted. Error: ' ME.message])
                end
            end
            
            fn = fieldnames(this.AppList);
            for i = 1:length(fn)
                try 
                    delete(this.AppList.(fn{i}).Listeners)
                catch ME
                    warning(['Collector listeners for ' fn{i} ...
                        ' could not be deleted. Error: ' ME.message])
                end
            end
        end
        
        function addInstrument(this, name, Instrument, varargin)
            assert(isvarname(name), ['Instrument name must be a valid ' ...
                'MATLAB variable name.'])
            
            assert(~ismember(name, this.running_instruments), ...
                ['Instrument ' name ' is already present in the ' ...
                'collector. Delete the existing instrument before ' ...
                'adding a new one with the same name.'])
            
            p = inputParser();
            
            % Optional - put the instrument in global workspace
            addParameter(p, 'make_global', true, @islogical);
            
            parse(p, varargin{:});
            
            S = struct( ...
                'Instance',         Instrument, ...
                'global_name',      '', ...
                'Listeners',        []);
            
            if p.Results.make_global
                global_name = name;
                
                % Assign instrument handle to a variable in global 
                % workspace for quick reference
                if isValidBaseVar(global_name)
                    base_ws_vars = evalin('base', 'who');
                    
                    warning(['A valid variable named ''' global_name ...
                        ''' already exists in global workspace.'])
                    
                    % Generate a new name excluding all the variable names 
                    % existing in the base workspace
                    global_name = matlab.lang.makeUniqueStrings( ...
                        global_name, base_ws_vars);
                end
                
                % Put the instrument in global workspace
                assignin('base', global_name, Instrument);
                
                S.global_name = global_name;
            end
            
            % Cleans up if the instrument is closed
            S.Listeners = addlistener(Instrument,'ObjectBeingDestroyed',...
                createInstrumentDeletedCallback(this, name));
            
            % InstrList is set observable, so it's better to assign value 
            % to it only once 
            this.InstrList.(name) = S;
        end
        
        % Get existing instrument
        function Instr = getInstrument(this, name)
            assert(isfield(this.InstrList, name), ...
                ['Name must correspond to one of the running ' ...
                'instruments.'])
            
            Instr = this.InstrList.(name).Instance;
        end
        
        % Interface for accessing internally stored instrument properties
        function val = getInstrumentProp(this, instr_name, prop_name)
            assert(isfield(this.InstrList, instr_name), ...
                ['''instr_name'' must correspond to one of the ' ...
                'running instruments.'])
            
            assert(isfield(this.InstrList.(instr_name), prop_name), ...
                ['''prop_name'' must be one of the following: ' ...
                var2str(fieldnames(this.InstrList.(instr_name)))])
            
            val = this.InstrList.(instr_name).(prop_name);
        end
        
        function setInstrumentProp(this, instr_name, prop_name, val)
            assert(isfield(this.InstrList, instr_name), ...
                ['''instr_name'' must correspond to one of the ' ...
                'running instruments.'])
            
            assert(isfield(this.InstrList.(instr_name), prop_name), ...
                ['''prop_name'' must be one of the following: ' ...
                var2str(fieldnames(this.InstrList.(instr_name)))])
            
            this.InstrList.(instr_name).(prop_name) = val;
        end
        
        function addApp(this, App, name)
            assert(~isfield(this.AppList, name), ['App with name ''' ...
                name ''' is already present in the collector.'])
            
            S = struct( ...
                'Instance',     App, ...
                'Listeners',    []);
            
            % Set up a listener that will update the list when the app
            % is deleted
            S.Listeners = addlistener(App, 'ObjectBeingDestroyed', ...
                createAppDeletedCallback(this, name));
            
            this.AppList.(name) = S;
        end
        
        function App = getApp(this, name)
            assert(isfield(this.AppList, name), [name ...
                ' does not correspond to any of the running apps.'])
            
            App = this.AppList.(name).Instance;
        end
        
        % Collects headers for open instruments with the header flag on
        function Mdt = readInstrumentSettings(this, varargin)
            p = inputParser();
            addParameter(p, 'instr_list', {}, @iscellstr);
            parse(p, varargin{:});
            
            if ~ismember('instr_list', p.UsingDefaults)
                instr_list = p.Results.instr_list;
            else
                instr_list = this.running_instruments;
            end
            
            Mdt = MyMetadata.empty();
            
            for i = 1:length(instr_list)
                name = this.running_instruments{i};
                
                try
                    TmpMdt = readSettings(this.InstrList.(name).Instance);
                    TmpMdt.title = name;
                    Mdt = [Mdt, TmpMdt]; %#ok<AGROW>
                catch ME
                    warning(['Error while reading metadata from ' ...
                        '%s: %s'], name, ME.message)
                end
            end
        end
        
        function bool = isrunning(this, name)
            assert(ischar(name)&&isvector(name),...
                'Instrument name must be a character vector, not %s',...
                class(name));
            bool = ismember(name, this.running_instruments);
        end
        
        % Remove instrument from collector without deleting the instrument 
        % object
        function removeInstrument(this, name)
            if isrunning(this, name)
                try 
                    delete(this.InstrList.(name).Listeners)
                catch ME
                    warning(['Listeners for ' name ' could not be ' ...
                        'deleted. Error: ' ME.message])
                end
                
                % Remove the instrument entries
                this.InstrList = rmfield(this.InstrList, name);
            end
        end
        
        function removeApp(this, name)
            if isfield(this.AppList, name)
                try 
                    delete(this.AppList.(name).Listeners)
                catch ME
                    warning(['Listeners for ' name ' could not be ' ...
                        'deleted. Error: ' ME.message])
                end
                
                this.AppList = rmfield(this.AppList, name);
            end
        end
        
        % Delete all presesently running instruments and apps.
        % We rely on the deletion callbacks to do cleanup.
        function flush(this)
            instr_names = this.running_instruments;
            for i = 1:length(instr_names)
                delete(this.InstrList.(instr_names{i}).Instance);
            end
            
            app_names = this.running_apps;
            for i = 1:length(app_names)
                
                % Delete by closing the app window
                closeApp(this.AppList.(app_names{i}).Instance);
            end
        end
        
        % Create metadata that stores information about the Collector 
        % state
        function Mdt = getMetadata(this)
            
            % Create new metadata if it has not yet been initialized
            if isempty(this.Metadata)
                this.Metadata = MyMetadata('title', 'SessionInfo');
                
                addParam(this.Metadata, ...
                    'session_name', this.session_name, ...
                    'comment', 'Measurement session name');
                
                addParam(this.Metadata, 'instruments', {}, 'comment', ...
                    'Instruments active during the session');
                
                addParam(this.Metadata, 'apps', {}, 'comment', ...
                    'Applications active during the session');
                
                addParam(this.Metadata, 'InstrProps', struct(), ...
                    'comment', ['Instrument properties. gui_position ' ...
                    'has format [x, y] and is measured in pixels.']);
                
                addParam(this.Metadata, 'AppProps', struct());
            end
            
            % Introduce a shorthand notation
            M = this.Metadata;
            
            % Update metadata parameters
            M.ParamList.session_name = this.session_name;
            M.ParamList.instruments = this.running_instruments;
            M.ParamList.apps = this.running_apps;
                
            for i = 1:length(this.running_instruments)
                nm = this.running_instruments{i};
                
                M.ParamList.InstrProps.(nm).is_global = ...
                    ~isempty(this.InstrList.(nm).global_name);
                
                % Indicate if the instrument has gui
                has_gui = isprop(this.InstrList.(nm).Instance, 'Gui') &&...
                    ~isempty(this.InstrList.(nm).Instance.Gui);
                
                M.ParamList.InstrProps.(nm).has_gui = has_gui;
                
                if has_gui
                    
                    % Add the position of GUI on the screen in pixels
                    Fig = findFigure(this.InstrList.(nm).Instance.Gui);
                    original_units = Fig.Units;
                    Fig.Units = 'pixels';
                    
                    % We record only x and y position but not the width and
                    % hight of the window, as the latter is a possible 
                    % subject to change
                    pos = Fig.Position(1:2);
                    
                    % Restore the figure settings
                    Fig.Units = original_units;
                    
                    M.ParamList.InstrProps.(nm).gui_position = pos;
                else
                    M.ParamList.InstrProps.(nm).gui_position = '';
                end
            end
            
            % Add information about running apps
            for i = 1:length(this.running_apps)
                nm = this.running_apps{i};
                
                M.ParamList.AppProps.(nm).class = class( ...
                    this.AppList.(nm).Instance);
                
                % Add the position of GUI on the screen in pixels
                Fig = findFigure(this.AppList.(nm).Instance);
                
                if isempty(Fig)
                    
                    % An app should in principle have a figure, we skip
                    % it if it does not
                    M.ParamList.AppProps.(nm).position = '';
                    continue
                end
                
                original_units = Fig.Units;
                Fig.Units = 'pixels';

                % We record only x and y position but not the width and
                % hight of the window, as the latter is a possible 
                % subject to change
                pos = Fig.Position(1:2);

                % Restore the figure settings
                Fig.Units = original_units;

                M.ParamList.AppProps.(nm).position = pos;
            end
            
            Mdt = copy(M);
        end
    end
    
    methods (Access = private)
        function f = createInstrumentDeletedCallback(this, name)
            function instrumentDeletedCallback(~, ~)

                % Clear the base workspace wariable
                gn = this.InstrList.(name).global_name;
                if ~isempty(gn)
                    try
                        evalin('base', sprintf('clear(''%s'');', gn));
                    catch ME
                        warning(['Could not clear global variable ''' ...
                            gn '''. Error: ' ME.message]);
                    end
                end

                % Remove the instrument entry from Collector
                removeInstrument(this, name);
            end
            
            f = @instrumentDeletedCallback;
        end
        
        function f = createAppDeletedCallback(this, name)
            function appDeletedCallback(~, ~)
                removeApp(this, name);
            end
            
            f = @appDeletedCallback;
        end
    end
    
    methods (Static = true)
        
        % Singletone constructor.
        function this = instance()
            persistent UniqueInstance

            if isempty(UniqueInstance)||(~isvalid(UniqueInstance))
                this = MyCollector();
                UniqueInstance = this;
            else
                this = UniqueInstance;
            end
        end
    end
    
    methods
        function val = get.running_instruments(this)
            val = fieldnames(this.InstrList);
        end
        
        function val = get.running_apps(this)
            val = fieldnames(this.AppList);
        end
    end
end
