% Class featuring a specialized framework for instruments supporting SCPI
%
% Undefined/dummy methods:
%   queryString(this, cmd)
%   writeString(this, cmd)
%   createCommandList(this)

classdef MyScpiInstrument < MyInstrument
    
    methods (Access = public)
        function this = MyScpiInstrument()
            
        end
        
        % Extend the functionality of base class method
        function addCommand(this, tag, command, varargin)
            p = inputParser();
            p.KeepUnmatched = true;
            addRequired(p,'command',@ischar);
            addParameter(p,'access','rw',@ischar);
            addParameter(p,'format','%e',@ischar);
            
            % Command ending for reading
            addParameter(p,'read_ending','?',@ischar);
            
            % Command ending for writing, e.g. '%10e'
            addParameter(p,'write_ending','',@ischar);
            parse(p, command, varargin{:});
            
            % Supply the remaining parameters to the base class method
            unmatched_nv = struct2namevalue(p.Unmatched);
            addCommand@MyInstrument(this, tag, unmatched_nv{:});
            
            vl = this.CommandList.(tag).value_list;
            if ~isempty(vl) && any(cellfun(@ischar, vl))
                
                % Put only unique full-named values in the value list
                [long_vl, short_vl] = splitValueList(this, vl);
                this.CommandList.(tag).value_list = long_vl;

                % For validation, use an extended list made of full and   
                % abbreviated name forms and case-insensitive comparison
                this.CommandList.(tag).validationFcn = ...
                    @(x) any(cellfun(@(y) isequal(y, lower(x)), ...
                    [long_vl, short_vl]));
                
                this.CommandList.(tag).postSetFcn = @this.toStandardForm;
            end
            
            % Introduce variables for brevity
            format = p.Results.format;
            write_ending = p.Results.write_ending;
            
            smb = findReadFormatSymbol(this, format);
            if smb == 'b'
                % '%b' is a non-MATLAB format specifier that is introduced
                % to be used with logical variables
                format = replace(format,'%b','%i');
                write_ending = replace(write_ending,'%b','%i');
            end
            
            % Assign a validation function based on the value format
            if isempty(this.CommandList.(tag).validationFcn)
                switch smb
                    case {'d','f','e','g'}
                        this.CommandList.(tag).validationFcn = @isnumeric;
                    case 'i'
                        this.CommandList.(tag).validationFcn = ...
                            @(x)(floor(x)==x);
                    case 's'
                        this.CommandList.(tag).validationFcn = @ischar;
                    case 'b'
                        this.CommandList.(tag).validationFcn = ...
                            @(x)(x==0 || x==1);
                end
            end
            
            % Add the full read form of the command, e.g. ':FREQ?'
            if contains(p.Results.access,'r')
                read_command = [p.Results.command, p.Results.read_ending];
                this.CommandList.(tag).readFcn = ...
                    @()sscanf(queryCommand(this, read_command), format);
            else
                read_command = '';
            end
            this.CommandList.(tag).read_command = read_command;
            
            % Add the full write form of the command, e.g. ':FREQ %e'
            if contains(p.Results.access,'w')
                if ismember('write_ending', p.UsingDefaults)
                    write_command = [p.Results.command, ' ', format];
                else
                    write_command = [p.Results.command, write_ending];
                end
                this.CommandList.(tag).writeFcn = ...
                    @(x)writeCommand(this, sprintf(write_command, x));
            else
                write_command = '';
            end
            this.CommandList.(tag).write_command = write_command;
            
            % Store the format
            this.CommandList.(tag).format = format;
        end
        
        % Redefine the base class method to use a single read operation for
        % faster communication
        function read_cns = sync(this)
            cns = this.command_names;
            ind_r = structfun(@(x) ~isempty(x.read_command), ...
                this.CommandList);
            
            read_cns = cns(ind_r); % List of names of readable commands
            
            read_commands = cellfun(...
                @(x) this.CommandList.(x).read_command, read_cns,...
                'UniformOutput',false);
            
            res_list = queryCommand(this, read_commands{:});
            
            if length(read_cns)==length(res_list)
                
                % Assign outputs to the class properties
                for i=1:length(read_cns)
                    val = sscanf(res_list{i},...
                            this.CommandList.(read_cns{i}).format);
                    
                    if ~isequal(this.CommandList.(tag).last_value, val)
                        
                        % Assign value without writing to the instrument
                        this.CommandList.(read_cns{i}).Psl.Enabled = false;
                        this.(read_cns{i}) = val;
                        this.CommandList.(read_cns{i}).Psl.Enabled = true;
                    end
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
        
        %% Misc utility methods
        
        % Split the list of string values into a full-form list and a
        % list of abbreviations, where the abbreviated forms are inferred  
        % based on case. For example, the value that has the full name 
        % 'AVErage' has the short form 'AVE'.
        function [long_vl, short_vl] = splitValueList(~, vl)
            short_vl = cell(1, length(vl)); % Abbreviated forms
            
            % Iterate over the list of values
            for i=1:length(vl)
                
                % Short forms exist only for string values
                if ischar(vl{i})
                    idx = isstrprop(vl{i},'upper');
                    short_form = vl{i}(idx);
                    if ~isequal(vl{i}, short_form)
                        short_vl{i} = short_form;
                    end
                end
            end
            
            % Remove duplicates
            short_vl = unique(lower(short_vl));
            
            % Make the list of full forms
            long_vl = setdiff(lower(vl), short_vl);  
        end
        
        % Return the long form of value from value_list 
        function std_val = toStandardForm(this, cmd)
            assert(ismember(cmd, this.command_names), ['''' cmd ...
                ''' is not an instrument command.'])

            val = this.(cmd);
            value_list = this.CommandList.(cmd).ext_value_list;
            
            % Standardization is applicable to char-valued properties which
            % have value list
            if isempty(value_list) || ~ischar(val)
                std_val = val;
                return
            end

            % find matching values
            n = length(val);
            ismatch = cellfun( ...
                @(x) strncmpi(val, x, min([n, length(x)])), value_list);
            
            assert(any(ismatch), ...
                sprintf(['%s is not present in the list of values ' ...
                'of command %s.'], val, cmd));

            % out of the matching values pick the longest
            mvals = value_list(ismatch);
            n_el = cellfun(@(x) length(x), mvals);
            std_val = mvals{n_el==max(n_el)};
        end
        
        % Find the format specifier symbol and options
        function smb = findReadFormatSymbol(~, fmt_spec)
            ind_p = strfind(fmt_spec,'%');
            ind = ind_p+find(isletter(fmt_spec(ind_p:end)),1)-1;
            smb = fmt_spec(ind);
            
            assert(ind_p+1 == ind, ['Correct reading format must not ' ...
                'have characters between ''%'' and format symbol.'])
        end
    end
end

