% Class for controlling HighFinesse wavelengthmeter, tested with WS6-200 

classdef MyHfWs < handle
    
    properties (Access=public)
        name = ''
        
        % Files containg the functions for communication with
        % wavelengthmeter, dll and header
        dllname = 'wlmData.dll'
        headername = 'wlmData.hml'
        
        % Timeout for trying to run the wavelengthmeter server app
        run_server_timeout = 60 % seconds
    end
    
    properties (GetAccess=public, SetAccess=protected)
        % These properties use get methods to read value every time they
        % are addressed
        wavelength = 0  % Wavelength in nm
        frequency = 0   % Frequency in THz
        
        idn_str = ''
    end
    
    properties (Dependent=true)
        libname
    end
    
    methods (Access=public)
        %% Constructor and destructor
        
        % Constructor can accept dummy 'interface' and 'address' arguments,
        % they will be stored in P.unmatched_nv
        function this = MyHfWs(varargin)
            P=MyClassParser(this);
            P.PartialMatching=false;
            processInputs(P, this, varargin{:});
            
            % Load dll library and its header
            loadWlmLib(this);
            
            % Check if the wavelengthmeter software is running
            if ~isServerRunning(this)
                disp(['Wavelength meter server apptication ', ...
                    'is not running. Attempting to start.'])
                runServer(this);
                startMeas(this);
            end
        end
        
        %% Communication methods
        
        function loadWlmLib(this)
            dll_path = which(this.dllname);
            if isempty(dll_path)
                error([this.dllname,' is not found. This library ',...
                    'needs to be present on Matlab path.'])
            end
            header_path = which(this.headername);
            if isempty(header_path)
                error([this.headername,' is not found. This header ',...
                    'file needs to be present on Matlab path.'])
            end
            
            if ~libisloaded(this.libname)
                fprintf('Loading %s library with %s header\n', ...
                    this.dllname, this.headername);
                loadlibrary(dll_path, header_path);
            end
        end
        
        function ret_val=readWavelength(this, varargin)
            p=inputParser();
            addParameter(p, 'n_ch', 1, @(x)assert( (mod(x,1)==0) && ...
                (x>=1) && (x<=8), ...
                'Channel number must be integer between 1 and 8.'))
            parse(p, varargin{:})
            
            n_ch=p.Results.n_ch;
            
            % read out the measured wavelength
            ret_val = calllib(this.libname,'GetWavelengthNum',n_ch,0);
        end
        
        function ret_val=readFrequency(this, varargin)
            p=inputParser();
            addParameter(p, 'n_ch', 1, @(x)assert( (mod(x,1)==0) && ...
                (x>=1) && (x<=8), ...
                'Channel number must be integer between 1 and 8.'))
            parse(p, varargin{:})
            
            n_ch=p.Results.n_ch;
            
            % read out the measured wavelength
            ret_val = calllib(this.libname,'GetFrequencyNum',n_ch,0);
        end
        
        % Run the wavelengthmeter control program
        function runServer(this)
            T=timer('Period',0.5,...
                'ExecutionMode','fixedDelay',...
                'TasksToExecute', ceil(this.run_server_timeout/0.5));
            T.TimerFcn=@(x,y)this.runServerTimerCallback(x,y);
            
            % cCtrlWLMShow: 1 - displays the window of wlm server 
            % application if it was hidden and starts the server if it is
            % not running
            if calllib(this.libname,'ControlWLM',1,0,0) == 1
                start(T);
                wait(T);
            else
                warning('Wavelengthmeter server app could not be started.')
            end
            
            % Clean up
            delete(T);
        end
        
        function bool=isServerRunning(this)
            bool=calllib(this.libname,'Instantiate',0,0,0,0);
        end
        
        % Start continuous measurement on the server
        function stat=startMeas(this)
            stat=calllib(this.libname,'Operation',hex2dec('0002'));
        end
        
        % Stop measurement on the server
        function stat=stopMeas(this)
            stat=calllib(this.libname,'Operation',hex2dec('0000'));
        end
        
        % Return the identification string of the device
        function str = idn(this)
            % Get the device information
            % Wavelengthmeter type can be 5 to 8
            type = calllib(this.libname,'GetWLMVersion',0);
            % Version number
            vers = calllib(this.libname,'GetWLMVersion',1);
            % Software version
            soft_vers = calllib(this.libname,'GetWLMVersion',2);
            str=['WS',num2str(type),', Version ',num2str(vers),...
                ', Software version ' num2str(soft_vers)];
        end
        
        %% Measurement headers
        
        function Hdr=readHeader(this)
            Hdr=MyMetadata();
            % Generate valid field name from instrument name if present and
            % class name otherwise
            if ~isempty(this.name)
                field_name=genvarname(this.name);
            else
                field_name=class(this);
            end
            addField(Hdr, field_name);
            % Add identification string as parameter
            addParam(Hdr, field_name, 'idn', this.idn_str);
            
            % Calculate wavelength in vacuum from frequency to avoid 
            % vaccum/air ambiguity
            f=this.frequency;
            c=299792458; % (m/s), speed of light
            % Print with 9 digits of precision which corresponds to 
            % kHz-scale resolution in the visible range. 
            % This should be safely beyond the instrument resolution.   
            wl=sprintf('%.9f',(c/(f*1e12))*1e9);
            if f<=0
                % The last measurement was not ok, so get the error code
                % instead of the value
                wl=readErrorFromCode(this, f);
            end
            addParam(Hdr, field_name, 'wavelength', wl, ...
                'comment', '(nm), in vacuum');
        end
        
        %% Auxiliary functions
        
        %Convert error codes returned by readWavelength and 
        %readFrequency commands to message
        function str=readErrorFromCode(~, code)
            if code>0
                str='Measurement ok';
                return
            end
            
            switch code
                case 0
                    str='No value measured';
                case -1
                    str='The wavelengthmeter has not detected any signal';
                case -2
                    str=['The wavelengthmeter has not detected a ',...
                        'calculatable signal'];
                case -3
                    str='Underexposed';
                case -4
                    str='Overexposed';
                case -5
                    str=['Server application is not running or ', ...
                        'wavelength meter is not active or available'];
                case -6
                    str=['The caller function is not avaliable for ',...
                        'this version of wavelengthmeter'];
                case -8
                    str='ErrNoPulse';
                otherwise
                    str='Unknown error';
            end
        end
    end
    
    %% Auxiliary pivate methods
    
    methods (Access=private)
        
        function runServerTimerCallback(this, Timer, ~)
            if ~isServerRunning(this)
                % Check if the timer has reached its limit
                if Timer.TasksExecuted>=Timer.TasksToExecute
                    warning(['Timeout for running the server ',...
                        'app (%is) is exceeded.'], this.run_server_timeout)
                end
            else
                stop(Timer);
            end
        end
    end
    
    %% Set and get methods
    methods
        
        function set.dllname(this, val)
            assert(ischar(val) && isvector(val), ['''dllname'' must be '...
                'a character vector.'])
            [~,~,ext]=fileparts(this.dllname);
            assert(strcmpi(ext,'dll'), ['''dllname'' must be a ',...
                'dynamic-link library and have extension .dll'])
            this.dllname=val;
        end
        
        function set.headername(this, val)
            assert(ischar(val) && isvector(val), ['''headername'' must be '...
                'a character vector.'])
            this.headername=val;
        end
        
        function nm=get.libname(this)
            % dll name without extension
            [~,nm,~]=fileparts(this.dllname);
        end
        
        function wl=get.wavelength(this)
            wl=readWavelength(this);
        end
        
        function wl=get.frequency(this)
            wl=readFrequency(this);
        end
    end
    
end

