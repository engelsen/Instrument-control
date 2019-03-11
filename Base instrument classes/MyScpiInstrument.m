% Class featuring a specialized framework for instruments supporting SCPI 

classdef MyScpiInstrument < MyInstrument
    
    methods (Access = public)
        function this = MyScpiInstrument()
            
        end
        
        % Extend the functionality of base class method
        function addCommand(this, tag, command, varargin)
            p=inputParser();
            p.KeepUnmatched=true;
            addRequired(p,'command',@ischar);
            addParameter(p,'access','rw',@ischar);
            addParameter(p,'format','%e',@ischar);
            addParameter(p,'read_form','',@ischar);
            addParameter(p,'write_form','',@ischar);
            parse(p, command, varargin{:});
            
            % Supply the remaining parameters to the base function
            unmatched_nv=struct2namevalue(p.Unmatched);
            addCommand@MyInstrument(this, tag, unmatched_nv{:});
            
            val_list = this.CommandList.(tag).val_list;
            
            % Make an extended list of values consisting of full and
            % abbreviated forms
            this.CommandList.(tag).ext_val_list = extendValList(this, tag);
            
            % Keep only unique full-name values in the main list and 
            % convert to lowercase (as SCPI commands are case-insensitive)
            this.CommandList.(tag).val_list = contractValList(this, tag);
            
            if contains(p.Results.access,'r')
                if ismember('read_form', p.UsingDefaults)
                    read_command = [p.Results.command, '?'];
                else
                    read_command = [p.Results.command, p.Results.read_form];
                end
                this.CommandList.(tag).readFcn = ...
                    @()sscanf(queryCommand(this, read_command), p.Results.format);
            else
                read_command = '';
            end
            this.CommandList.(tag).read_command = read_command;
            
            if contains(p.Results.access,'w')
                if ismember('write_form', p.UsingDefaults)
                    write_command = [p.Results.command, ' ', p.Results.format];
                else
                    write_command = [p.Results.command, p.Results.write_form];
                end
                this.CommandList.(tag).writeFcn = ...
                    @(x)writeCommand(this, sprintf(write_command, x));
            else
                write_command = '';
            end
            this.CommandList.(tag).write_command = write_command;
            
            this.CommandList.(tag).format = p.Results.format;
        end
        
        % Redefine the base class method to use a single read operation for
        % faster communication
        function sync(this)
            cns = this.command_names;
            ind_r = structfun(@(x) ~isempty(x.read_command), ...
                this.CommandList);
            
            read_cns = cns(ind_r); % List of names of readable commands
            
            read_commands = cellfun(...
                @(x) this.CommandList.(x).read_command, read_cns,...
                'UniformOutput',false);
            
            res_list = queryCommand(this, read_commands{:});
            
            query_successful=(length(read_cns)==length(res_list));
            if query_successful
                % Assign outputs to the class properties
                for i=1:length(read_cns)
                    this.(read_cns{i})=sscanf(res_list{i},...
                        this.CommandList.(read_cns{i}).format);
                end
            else
                warning(['Not all the properties could be read, ',...
                    'instrument class values are not updated.']);
            end
        end
    end
    
    methods (Access = protected)
        %% Write/query
        % These methods implement handling multiple SCPI commands. Unless 
        % overloaded, for communication with the device they rely on  
        % write/readString methods, which particular subclasses must 
        % implement or inherit separately.
        
        % Write command strings listed in varargin
        function writeCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';');
                cmd_str=cmd_str{1};
                writeString(this, cmd_str);
            end
        end
        
        % Query commands and return the resut as cell array of strings
        function res_list = queryCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';');
                cmd_str=cmd_str{1};
                res_str=queryString(this, cmd_str);
                % Drop the end-of-the-string symbol and split
                res_list=split(deblank(res_str),';');
            else
                res_list={};
            end
        end
        
        %% Methods for command set and get callbacks
        
        function scpiWriteFcn(this, tag, val)
        end
        
        function val = scpiReadFcn(this, tag)
        end
        
        %% Misc utility methods
        
        % Add the list of values, if needed extending it to include
        % short forms. For example, for the allowed value 'AVErage'
        % its short form 'AVE' also will be added.
        function [ext_vl, cont_vl] = extendValList(~, vl)
            short_vl = {};
            long_vl = {};
            for i=1:length(vl)
                if ischar(vl{i})
                    idx = isstrprop(vl{i},'upper');
                    short_form = vl{i}(idx);
                    
                    % Add the short form to the list of values if it was
                    % not included explicitly
                    if ~ismember(short_form, vl)
                        short_vl{end+1}=short_form; %#ok<AGROW>
                    end
                    short_vl{end+1}=short_form; %#ok<AGROW>
                end
            end
            ext_vl=[vl, short_vl];
        end
        
        % Return the long form of value from val_list 
        function std_val = toStandardForm(this, cmd, val)
            assert(ismember(cmd, this.command_names), ['''' cmd ...
                ''' is not an instrument command.'])

            val_list = this.CommandList.(cmd).ext_val_list;
            
            % Standardization is applicable to char-valued properties which
            % have value list
            if isempty(val_list) || ~ischar(val)
                std_val = val;
                return
            end

            % find matching values
            n = length(val);
            ismatch = cellfun( ...
                @(x) strncmpi(val, x, min([n, length(x)])), val_list);
            
            assert(any(ismatch), ...
                sprintf(['%s is not present in the list of values ' ...
                'of command %s.'], val, cmd));

            % out of the matching values pick the longest
            mvals = val_list(ismatch);
            n_el = cellfun(@(x) length(x), mvals);
            std_val = mvals{n_el==max(n_el)};
        end
        
        function std_list = listToStandardForm(this, cmd)
            if ~ismember(cmd,this.command_names)
                warning('%s is not a valid command',cmd);
                std_list = {};
                return
            end
            vlist = this.CommandList.(cmd).val_list;
            % Select the commands, which appear only once in the beginnings 
            % of the strings in val_list
            long_val_ind = cellfun(...
                @(x)(sum(startsWith(vlist,x,'IgnoreCase',true))==1),vlist);
            std_list = vlist(long_val_ind); 
        end
    end
    
end

