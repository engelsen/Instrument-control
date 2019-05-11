% Class featuring a specialized framework for instruments supporting SCPI
%
% Undefined/dummy methods:
%   queryString(this, cmd)
%   writeString(this, cmd)

classdef MyScpiInstrument < MyInstrument
    
    methods (Access = public)
        
        % Extend the functionality of base class method
        function addCommand(this, tag, command, varargin)
            p = inputParser();
            p.KeepUnmatched = true;
            addRequired(p, 'command', @ischar);
            
            addParameter(p, 'access', 'rw', @ischar);
            addParameter(p, 'format', '%e', @ischar);
            addParameter(p, 'value_list', {}, @iscell);
            addParameter(p, 'validationFcn', function_handle.empty(), ...
                @(x)isa(x, 'function_handle'));
            addParameter(p, 'default', 0);
            
            % Command ending for reading
            addParameter(p, 'read_ending', '?', @ischar);
            
            % Command ending for writing, e.g. '%10e'
            addParameter(p, 'write_ending', '', @ischar);
            parse(p, command, varargin{:});
            
            % Create a list of remaining parameters to be supplied to
            % the base class method
            sub_varargin = struct2namevalue(p.Unmatched);
            
            % Introduce variables for brevity
            format = p.Results.format;
            write_ending = p.Results.write_ending;
            
            if ismember('format', p.UsingDefaults) && ...
                    ~ismember('write_ending', p.UsingDefaults)
                
                % Extract format specifier and symbol from the write ending
                [smb, format] = parseFormat(this, write_ending);
            else
                
                % Extract format symbol
                smb = parseFormat(this, format);
            end
            
            if ismember('b', smb)
                
                % '%b' is a non-MATLAB format specifier that is introduced
                % to designate logical variables
                format = replace(format, '%b', '%i');
                write_ending = replace(write_ending, '%b', '%i');
            end
            this.CommandList.(tag).format = format;
            
            % Add the full read form of the command, e.g. ':FREQ?'
            if contains(p.Results.access, 'r')
                read_command = [p.Results.command, p.Results.read_ending];
                readFcn = ...
                    @()sscanf(queryString(this, read_command), format);
                sub_varargin = [sub_varargin, {'readFcn', readFcn}];
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
                writeFcn = ...
                    @(x)writeString(this, sprintf(write_command, x));
                sub_varargin = [sub_varargin, {'writeFcn', writeFcn}];
            else
                write_command = '';
            end
            this.CommandList.(tag).write_command = write_command;
            
            % If the value list contains textual values, extend it with
            % short forms and add a postprocessing function
            value_list = p.Results.value_list;
            validationFcn = p.Results.validationFcn;
            if ~isempty(value_list)
                if any(cellfun(@ischar, value_list)) 
                
                    % Put only unique full-named values in the value list
                    [long_vl, short_vl] = splitValueList(this, value_list);
                    value_list = long_vl;

                    % For validation, use an extended list made of full and   
                    % abbreviated name forms and case-insensitive 
                    % comparison
                    validationFcn = createScpiListValidationFcn(this, ...
                        [long_vl, short_vl]);

                    postSetFcn = createToStdFormFcn(this, tag, long_vl);

                    sub_varargin = [sub_varargin, ...
                        {'postSetFcn', postSetFcn}];
                end
            end
            
            % Assign validation function based on the value format
            if isempty(validationFcn)
                validationFcn = createArrayValidationFcn(this, smb);
            end
            
            sub_varargin = [sub_varargin, { ...
                'value_list',       value_list, ...
                'validationFcn',    validationFcn}];
            
            % Assign default based on the format of value 
            if ~ismember('default', p.UsingDefaults)
                default = p.Results.default;
            elseif ~isempty(value_list)
                default = value_list{1};
            else
                default = createValidValue(this, smb);
            end
            
            sub_varargin = [sub_varargin, {'default', default}];
            
            % Execute the base class method
            addCommand@MyInstrument(this, tag, sub_varargin{:});
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
            
            res_list = queryStrings(this, read_commands{:});
            
            if length(read_cns)==length(res_list)
                
                % Assign outputs to the class properties
                for i=1:length(read_cns)
                    tag = read_cns{i};
                    
                    val = sscanf(res_list{i}, ...
                            this.CommandList.(tag).format);
                    
                    if ~isequal(this.CommandList.(tag).last_value, val)
                        
                        % Assign value without writing to the instrument
                        this.CommandWriteEnabled.(tag) = false;
                        this.(tag) = val;
                        this.CommandWriteEnabled.(tag) = true;
                    end
                end
            else
                warning(['Not all the properties could be read, ',...
                    'instrument class values are not updated.']);
            end
        end
    
        %% Write/query
        % These methods implement handling multiple SCPI commands. Unless 
        % overloaded, they rely on write/readString methods for   
        % communication with the device, which particular subclasses must 
        % implement or inherit separately.
        
        % Write command strings listed in varargin
        function writeStrings(this, varargin)
            if ~isempty(varargin)
                
                % Concatenate commands and send to the device
                cmd_str = join(varargin,';');
                cmd_str = cmd_str{1};
                writeString(this, cmd_str);
            end
        end
        
        % Query commands and return the resut as cell array of strings
        function res_list = queryStrings(this, varargin)
            if ~isempty(varargin)
                
                % Concatenate commands and send to the device
                cmd_str = join(varargin,';');
                cmd_str = cmd_str{1};
                res_str = queryString(this, cmd_str);
                
                % Drop the end-of-the-string symbol and split
                res_list = split(deblank(res_str),';');
            else
                res_list = {};
            end
        end
    end
    
    methods (Access = protected)
        %% Misc utility methods
        
        % Split the list of string values into a full-form list and a
        % list of abbreviations, where the abbreviated forms are inferred  
        % based on case. For example, the value that has the full name 
        % 'AVErage' has the short form 'AVE'.
        function [long_vl, short_vl] = splitValueList(~, vl)
            long_str_vl = {};   % Full forms of string values
            short_vl = {};      % Abbreviated forms of string values
            num_vl = {};        % Numeric values
            
            % Iterate over the list of values
            for i = 1:length(vl)
                
                % Short forms exist only for string values
                if ischar(vl{i})
                    long_str_vl{end+1} = vl{i};         %#ok<AGROW>
                    
                    % Add short form
                    idx = isstrprop(vl{i},'upper');
                    short_form = vl{i}(idx);
                    if ~isequal(vl{i}, short_form) && ~isempty(short_form)
                        short_vl{end+1} = short_form;   %#ok<AGROW>
                    end
                else
                    num_vl{end+1} = vl{i};              %#ok<AGROW>
                end
            end
            
            % Remove duplicates
            short_vl = unique(lower(short_vl));
            
            % Make the list of full forms
            long_vl = [num_vl, ...
                setdiff(lower(long_str_vl), short_vl, 'stable')];  
        end
        
        % Create a function that returns the long form of value from 
        % value_list 
        function f = createToStdFormFcn(this, cmd, value_list)
            function std_val = toStdForm(val)

                % Standardization is applicable to char-valued properties 
                % which have value list
                if isempty(value_list) || ~ischar(val)
                    std_val = val;
                    return
                end

                % find matching values
                n = length(val);
                ismatch = cellfun(@(x) strncmpi(val, x, ...
                    min([n, length(x)])), value_list);

                assert(any(ismatch), ...
                    sprintf(['%s is not present in the list of values ' ...
                    'of command %s.'], val, cmd));

                % out of the matching values pick the longest
                mvals = value_list(ismatch);
                n_el = cellfun(@(x) length(x), mvals);
                std_val = mvals{n_el==max(n_el)};
            end
            
            assert(ismember(cmd, this.command_names), ['''' cmd ...
                    ''' is not an instrument command.'])
                
            f = @toStdForm;
        end
        
        % Find the format specifier symbol and options
        function [smb, format] = parseFormat(~, fmt_spec)
            [start, stop, tok] = regexp(fmt_spec, '%([\d\.]*)([a-z])', ...
                'start', 'end', 'tokens');
            
            assert(~isempty(tok) && ~isempty(tok{1}{2}), ...
                ['Format symbol is not found in ' fmt_spec]);
            
            % The first cell index corresponds to different matches if   
            % there are more than one specifier
            smb = cellfun(@(x)x{2}, tok);
            
            % Return a substring that includes all the specifiers 
            format = fmt_spec(min(start):max(stop));
        end
        
        function createMetadata(this)
            createMetadata@MyInstrument(this);
            
            % Re-iterate the creation of command parameters to add the
            % format specifier
            for i = 1:length(this.command_names)
                cmd = this.command_names{i};
                addObjProp(this.Metadata, this, cmd, ...
                    'comment', this.CommandList.(cmd).info, ...
                    'format', this.CommandList.(cmd).format);
            end
        end
        
        % List validation function with case-insensitive comparison
        function f = createScpiListValidationFcn(~, value_list)
            function listValidationFcn(val)
                val = lower(val);
                assert( ...
                    any(cellfun(@(y) isequal(val, y), value_list)), ...
                    ['Value must be one from the following list:', ...
                    newline, var2str(value_list)]);
            end
            
            f = @listValidationFcn;
        end
        
        % smb is an array of format specifier symbols
        function f = createArrayValidationFcn(~, smb)
            function validateNumeric(val)
                assert((length(val) == length(smb)) && isnumeric(val), ...
                    sprintf(['Value must be a numeric array of length ' ...
                    '%i.'], length(smb)))
            end
            
            function validateInteger(val)
                assert((length(val) == length(smb)) && ...
                    all(floor(val) == val), sprintf(['Value must be ' ...
                    'an integer array of length %i.'], length(smb)))
            end
            
            function validateLogical(val)
                assert((length(val) == length(smb)) && ...
                    all(val==1 | val==0), ['Value must be a logical ' ...
                    'array of length ' length(smb) '.'])
            end
            
            function valudateCharacterString(val)
                assert(ischar(val), 'Value must be a character string.');
            end
            
            % Determine the type of validation function
            if all(smb == 's' | smb == 'c')
                f = @valudateCharacterString;
            elseif all(smb == 'b')
                f = @validateLogical;
            elseif all(smb == 'b' | smb == 'i')
                f = @validateInteger;
            else
                f = @validateNumeric;
            end
        end
        
        function val = createValidValue(~, smb)
            if all(smb == 's' | smb == 'c')
                val = '';
            elseif all(smb == 'b')
                val = false(length(smb), 1);
            else
                val = zeros(length(smb), 1);
            end
        end
    end
end

