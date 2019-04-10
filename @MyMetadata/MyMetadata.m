% MyMetadata stores parameter-value pairs and can be saved in a readable 
% format.
%
% Metadata parameters can be strings, numerical values or cells, as well as  
% any arrays and structures of such with arbitrary nesting. Sub-indices are 
% automatically expanded when saving.

classdef MyMetadata < dynamicprops & matlab.mixin.CustomDisplay & matlab.mixin.SetGet
    
    properties (Access = public)
        
        % Header sections are separated by [hdr_spec, title, hdr_spec]
        title = ''
        hdr_spec = '=='

        % Columns are separated by this symbol (space-tab by default)
        column_sep = ' \t'
        
        % Comments start from this symbol
        comment_sep = '%'
        line_sep = '\r\n'
        
        % Limit for column padding. Variables which take more space than
        % this limit are ignored when calculating the padding length.
        pad_lim = 15
    end
    
    properties (GetAccess = public, SetAccess = protected)
        ParamList = struct()
    end
    
    methods (Access = public)
        
        function this = MyMetadata(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        % Adds a new metadata parameter. 
        function addParam(this, param_name, value, varargin)
            assert(isvarname(param_name), ['Parameter name must be a ' ...
                'valid variable name.']);
            
            p = inputParser();
            
            % Format specifier for printing the value
            addParameter(p, 'fmt_spec', '', @ischar);
            
            % Comment to be added to the line
            addParameter(p, 'comment', '', @ischar);
            addParameter(p, 'SubStruct', struct('type',{},'subs',{}),...
                @isstruct)
            parse(p, varargin{:});
            
            % Add a dynamic property to store the parameter value
            H = addprop(this, param_name);
            H.Access = 'public';

            % Hide the dynamic property from the output of display() 
            % for beauty
            H.Hidden = true;
            
            % Initialize property with an empty variable of the same class 
            % as value, this is important if SubStruct is an array index. 
            this.(param_name) = feval([class(value),'.empty']);
 
            % Make sure that the comment does not contain new line or 
            % carriage return characters, which would mess up formating 
            % when saving the metadata
            [comment, is_mod] = toSingleLine(p.Results.comment);
            this.ParamList.(param_name).comment = comment;

            if is_mod
                warning(['Comment string for ''%s'' has been ' ...
                    'converted to single line.'], param_name);
            end

            this.ParamList.(param_name).fmt_spec = p.Results.fmt_spec;
            
            % Construct full subscript reference with respect to 'this' 
            S = [struct('type', '.', 'subs', param_name), ...
                p.Results.SubStruct];
            
            % Assign the value of parameter
            this = subsasgn(this, S, value);                                %#ok<NASGU>
        end
        
        function bool = isparam(this, param_name)
            bool = isfield(param_name, this.ParamList);
        end
        
        % Alias for addParam that is useful to ensure the correspondence  
        % between metadata parameter names and object property names. 
        function addObjProp(this, Obj, tag, varargin)
            addParam(this, tag, Obj.(tag), varargin{:});
        end
        
        % Print metadata in a readable form
        function str = mdt2str(this)
            
            % Make the function spannable over arrays
            if isempty(this)
                str = '';
                return
            elseif length(this) > 1
                str_arr = arrayfun(@(x)mdt2str(x), this, ...
                    'UniformOutput', false);
                str = [str_arr{:}];
                return
            end
            
            % Compose the list of parameter names expanded over subscripts
            % except for those which are already character arrays
            par_names = fieldnames(this.ParamList);
            
            % Expand parameters over subscripts, except for the character
            % arrays
            exp_par_names = cell(1, length(par_names));
            maxnmarr = zeros(1, length(par_names));
            
            for i=1:length(par_names)
                tmpval = this.ParamList.(par_names{i});
                exp_par_names{i} = printSubs(tmpval, ...
                    'own_name', par_names{i}, ...
                    'expansion_test',@(y) ~ischar(y));
                
                % Max name length for this parameter including subscripts
                maxnmarr(i)=max(cellfun(@(x) length(x), exp_par_names{i}));
            end
            
            % Calculate width of the name column
            name_pad_length = min(max(maxnmarr), this.pad_lim);
            
            % Compose list of parameter values converted to char strings
            par_strs = cell(1, length(par_names));
            
            % Width of the values column will be the maximum parameter
            % string width
            val_pad_length = 0;
            for i=1:length(par_names)
                TmpPar = this.ParamList.(par_names{i});
                
                for j=1:length(exp_par_names{i})
                    tmpnm = exp_par_names{i}{j};
                    TmpS = str2substruct(tmpnm);
                    
                    Subs = [struct('type','.','subs',name), Subs];  %#ok<AGROW>
            
                            % Assign the value of parameter
                            this = subsasgn(this, Subs, value);
                    if isempty(TmpS)
                        tmpval = TmpPar.value;
                    else
                        tmpval = subsref(TmpPar.value, TmpS);
                    end
                    
                    %Do the check to detect unsupported data type
                    if ischar(tmpval)&&~isvector(tmpval)&&~isempty(tmpval)
                        warning(['Argument ''%s'' is a multi-dimensional ',...
                            'character array. It will be converted to ',...
                            'single string during saving. Use cell',...
                            'arrays to save data as a set of separate ',...
                            'strings.'], tmpnm)
                        
                        % Flatten
                        tmpval = tmpval(:);
                    end
                    
                    % Check for new line symbols in strings
                    if (ischar(tmpval)||isstring(tmpval)) && ...
                            any(ismember({newline,sprintf('\r')},tmpval))
                        warning(['String value must not contain ',...
                            '''\\n'' and ''\\r'' symbols, replacing ',...
                            'them with '' ''.']);
                        tmpval=replace(tmpval,{newline,sprintf('\r')},' ');
                    end
                    
                    if isempty(TmpPar.fmt_spec)
                        
                        % Convert to string with format specifier
                        % extracted from the varaible calss
                        par_strs{i}{j} = var2str(tmpval);
                    else
                        par_strs{i}{j} = sprintf(TmpPar.fmt_spec, tmpval);
                    end
                    
                    % Find maximum length to determine the colum width, 
                    % but, for beauty, do not account for variables with 
                    % excessively long value strings
                    tmplen = length(par_strs{i}{j});
                    if (val_pad_length<tmplen) && (tmplen<=this.pad_lim)
                        val_pad_length = tmplen;
                    end
                end
            end
            
            cs = this.column_sep;
            ls = this.line_sep;
            
            % Make the output string. Start by printing the title.
            str = sprintf([this.hdr_spec, this.title, this.hdr_spec, ls]);

            par_fmt_spec = [sprintf('%%-%is', name_pad_length),...
                cs, sprintf('%%-%is', val_pad_length)];
            
            % Print parameters 
            for i=1:length(par_names)
                
                % Capitalize the first letter of comment
                comment = this.ParamList.(par_names{i}).comment;
                if ~isempty(comment)
                    fmt_comment = [this.comment_sep, ' '...
                        upper(comment(1)), comment(2:end)];
                else
                    fmt_comment = '';
                end
                
                % Iterate over the parameter subscripts
                for j=1:length(exp_par_names{i})
                    if j==1
                        
                        % Add the comment to first line 
                        str = [str, ...
                            sprintf([par_fmt_spec, cs, '%s', ls], ...
                            exp_par_names{i}{j}, par_strs{i}{j}, ...
                            fmt_comment)];                                  %#ok<AGROW>
                    else
                        str = [str, sprintf([par_fmt_spec, ls],...
                            exp_par_names{i}{j}, par_strs{i}{j})];          %#ok<AGROW>
                    end
                end
            end
            
            % Prints an extra line separator at the end
            str = [str, sprintf(ls)];
        end
        
        % Save metadata to a file
        function save(this, filename)
            fileID = fopen(filename,'a');
            fprintf(fileID, mdt2str(this));
            fclose(fileID);
        end
        
        % Create a structure from metadata array
        function MdtList = arrToStruct(this)
            MdtList = struct();
            
            for i = 1:length(this)
                fn = matlab.lang.makeValidName(this(i).title);
                MdtList.(fn) = this(i);
            end
        end
    end
    
    methods (Access = public, Static = true)
        
        % Create metadata indicating the present moment of time
        function TimeMdt = time(title)
            if nargin()>0
                assert(ischar(title)&&isvector(title),...
                    'Time field name must be a character vector')
            else
                title = 'Time';
            end
            
            TimeMdt = MyMetadata();
            TimeMdt.title = title;
            
            dv = datevec(datetime('now'));
            addParam(TimeMdt, 'Year',    dv(1), 'fmt_spec','%i');
            addParam(TimeMdt, 'Month',   dv(2), 'fmt_spec','%i');
            addParam(TimeMdt, 'Day',     dv(3), 'fmt_spec','%i');
            addParam(TimeMdt, 'Hour',    dv(4), 'fmt_spec','%i');
            addParam(TimeMdt, 'Minute',  dv(5), 'fmt_spec','%i');
            addParam(TimeMdt, 'Second',  floor(dv(6)), 'fmt_spec','%i');
            addParam(TimeMdt, 'Millisecond',...
                round(1000*(dv(6)-floor(dv(6)))),'fmt_spec','%i');
        end
        
        % Load metadata from file. Return all the entries found and  
        % the number of the last line read.
        function [MdtArr, n_end_line] = load(filename, varargin)
            fileID = fopen(filename,'r');
            
            MasterMdt = MyMetadata(varargin{:});
            
            % Loop initialization
            MdtArr = MyMetadata.empty();
            line_no = 0;
            
            % Loop continues until we reach the next header or we reach
            % the end of the file
            while ~feof(fileID)
                
                % Grabs the current line
                curr_line = fgetl(fileID);
                
                % Give a warning if the file is empty, i.e. if fgetl 
                % returns -1
                if curr_line == -1 
                    disp(['Read empty file ', filename, '.']);
                    break
                end
                
                % Skips if the current line is empty
                if isempty(deblank(curr_line))
                    continue
                end
                
                S = parseLine(MasterMdt, curr_line);
                
                switch S.type
                    case 'title'
                        
                        % Generate a valid identifier and add new metadata 
                        % to the output list
                        TmpMdt = MyMetadata(varargin{:}, 'title', S.match);
                        MdtArr = [MdtArr, TmpMdt]; %#ok<AGROW>
                    case 'paramval'
                        
                        % Add a new parameter-value pair to the current 
                        % metadata
                        [name, value, comment, Subs] = S.match{:};
                        
                        if ~isparam(TmpMdt, name)
                            addParam(TmpMdt, name, value, ...
                                'SubStruct', Subs, 'comment', comment);
                        else
                            Subs = [struct('type','.','subs',name), Subs];  %#ok<AGROW>
            
                            % Assign the value of parameter
                            this = subsasgn(this, Subs, value);  
                        end
                    otherwise
                        
                        % Exit
                        break
                end
                
                % Increment the counter
                line_no = line_no+1;
            end
            
            n_end_line = line_no;
            fclose(fileID);
        end
    end
    
    methods (Access = protected)
        
        % Parse string and determine the type of string
        function S = parseLine(this, str)
            S = struct( ...
                'type',     '', ...     % title, paramval, other
                'match',    []);        % parsed output
            
            % Check if the line contains a parameter - value pair.
            % First separate the comment if present
            pv_token = regexp(str, this.comment_sep, 'split', 'once');
             
            if length(pv_token)>1
                comment = pv_token{2};  % There is a comment
            else
                comment = '';           % There is no comment
            end

            % Then process name-value pair. Regard everything after
            % the first column separator as value.
            pv_token = regexp(pv_token{1}, this.column_sep, 'split', ...
                'once');
            
            % Remove leading and trailing blanks
            pv_token = strtrim(pv_token);

            if length(pv_token)>=2
                
                % A candidate for parameter-value pair is found. Infer 
                % the variable name and subscript reference.
                [Subs, name] = str2substruct(pv_token{1});
                
                if isvarname(name)
                    
                    % Attempt converting the value to a number
                    value = str2doubleHedged(pv_token{2});

                    S.type = 'paramval';
                    S.match = {name, value, comment, Subs};
                    return
                end
            end
            
            % Check if the line contains a title 
            title_exp = [this.hdr_spec, '(\w.*)', this.hdr_spec];
            title_token = regexp(str, title_exp, 'once', 'tokens');
            
            if ~isempty(title_token)
                
                % Title expression found
                S.type = 'title';
                S.match = title_token{1};
                return
            end
            
            % No match found
            S.type = 'other';
            S.match = {};
        end
        
        % Make custom footer for command line display 
        % (see matlab.mixin.CustomDisplay)        
        function str = getFooter(this)
            if length(this) == 1
                
                % For a single object display its properties
                str = ['Content:', newline, newline, ...
                    replace(mdt2str(this), sprintf(this.line_sep), newline)];
            elseif length(this) > 1
                
                % For a non-empty array of objects display titles
                str = sprintf('\tTitles:\n\n');
                
                for i = 1:length(this)
                    str = [str, sprintf('%i\t%s\n', i, this(i).title)]; %#ok<AGROW>
                end
                
                str = [str, newline];
            else
                
                % For an empty array display nothing
                str = '';
            end
        end
    end
end

