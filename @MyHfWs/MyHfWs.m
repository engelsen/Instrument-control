% Class for controlling HighFinesse wavelengthmeter, tested with WS6 

classdef MyHfWs < dynamicprops
    
    properties
        % Files containg the functions for communication with
        % wavelengthmeter, dll and header
        dllname = 'wlmData.dll';
        headername = 'wlmData.hml';
        
        wavelength
    end
    
    properties (Dependent=true)
        libname
    end
    
    methods (Access=public)
        
        function this = MyHfWs(varargin)
            P=MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            loadAssembly(this);
        end
        
        function loadAssembly(this)
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

            loadlibrary(dll_path, header_path)
        end
        
        function readWavelength(this)
            % read out the measured wavelength
            ret_val = calllib(this.libname,'GetWavelengthNum',0);
            switch ret_val
                case -5
                    disp('Error: wavelength meter software not running or wavelength meter is not active or available.')
                    ret_val = 0;
                    return;
                case -1
                    disp('Error: wavelength meter has not detected any signal.')
                    ret_val = 0;
                    return;
                case -3
                    disp('Error: signal on wavelength meter is too low')
                    ret_val = 0;
                    return;
            end
            this.wavelength=ret_val;
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
        
    end
end

