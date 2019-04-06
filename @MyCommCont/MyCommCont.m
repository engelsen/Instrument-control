% Communicator container.
% This class provides extended functionality for communication using VISA, 
% tcpip and serial objects or any other objects that have a similar usage. 

classdef MyCommCont < handle
    
    % Giving explicit set access to this class makes properties protected 
    % instead of private
    properties (GetAccess=public, SetAccess={?MyClassParser,?MyCommCont})     
        interface = 'serial'
        address = 'placeholder' 
    end
    
    properties (GetAccess = public, SetAccess = protected)
        Comm % Communication object    
    end
    
    methods (Access = public)
        
        %% Constructor and destructor
        
        function this = MyCommCont(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
            
            try
                connect(this);
            catch ME
                warning(ME.message);
                
                % Create a dummy
                this.Comm = serial('placeholder');
            end
            
            configureCommDefault(this);
        end
        
        function delete(this) 
            
            % Close the connection to the device
            try 
                closeComm(this);
            catch
                warning('Connection could not be closed.');
            end
            
            % Delete the device object
            try
                delete(this.Comm);
            catch
                warning('Communication object could not be deleted.');
            end
        end 
        
        %% Set up communication
        
        % Create an interface object
        function connect(this)
            switch lower(this.interface)
                
                % Use 'constructor' interface to create an object with
                % more that one parameter passed to the constructor
                case 'constructor'
                    
                    % In this case 'address' is a MATLAB command that  
                    % creates communication object when executed. 
                    % Such commands, for example, are returned by  
                    % instrhwinfo as ObjectConstructorName.
                    this.Comm=eval(this.address);
                case 'visa'
                    
                    % visa brand is 'ni' by default
                    this.Comm=visa('ni', this.address);
                case 'tcpip'
                    
                    % Works only with default socket. Use 'constructor'
                    % if socket or other options need to be specified
                    this.Comm=tcpip(this.address);
                case 'serial'
                    this.Comm=serial(this.address);
                otherwise
                    error(['Unknown interface ''' this.interface ...
                        ''', a communication object is not created.' ...
                        ' Valid interfaces are ',...
                        '''constructor'', ''visa'', ''tcpip'' and ''serial'''])
            end
        end
        
        % Set larger buffer sizes and longer timeout than the MATLAB default
        function configureCommDefault(this)
            comm_props = properties(this.Comm);
            if ismember('OutputBufferSize',comm_props)
                this.Comm.OutputBufferSize = 1e7; % bytes
            end
            if ismember('InputBufferSize',comm_props)
                this.Comm.InputBufferSize = 1e7; % bytes
            end
            if ismember('Timeout',comm_props)
                this.Comm.Timeout = 10; % s
            end
        end
        
        function bool = isopen(this)
            try
                bool = strcmp(this.Comm.Status, 'open');
            catch
                warning('Cannot access the communicator Status property');
                bool = false;
            end
        end
        
        % Opens the device if it is not open. Does not throw error if
        % device is already open for communication with another object, but
        % tries to close existing connections instead.
        function openComm(this)
            try
                fopen(this.Comm);
            catch
                
                % try to find and close all the devices with the same
                % VISA resource name
                instr_list = instrfind('RsrcName',this.Comm.RsrcName);
                fclose(instr_list);
                fopen(this.Comm);
                warning(['Multiple instrument objects of ' ...
                    'address %s exist'], this.address);
            end
        end
        
        function closeComm(this)
            fclose(this.Comm);
        end
        
        %% Communication
        
        % Write textual command
        function writeString(this, str)
            try
                fprintf(this.Comm, str);
            catch ME
                try
                    % Attempt re-opening communication
                    openComm(this);
                    fprintf(this.Comm, str);
                catch
                    rethrow(ME);
                end
            end
        end
        
        % Query textual command
        function result = queryString(this, str)
            try
                result = query(this.Comm, str);
            catch ME
                try
                    % Attempt re-opening communication
                    openComm(this);
                    result = query(this.Comm, str);
                catch
                    rethrow(ME);
                end
            end
        end
    end
end
