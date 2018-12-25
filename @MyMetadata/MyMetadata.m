% MyMetadata stores parameter-value pairs grouped by fields. MyMetadata can
% be saved and read in a readable text format.
% Parameters can be strings, numerical values or cells, as well as any 
% arrays and structures of such with arbitrary nesting. Sub-indices are 
% automatically expanded when saving.
% If instantiated as MyMetadata(load_path) 
% then the content is loaded from file

classdef MyMetadata < dynamicprops
    properties (Access=public)
        % Header sections are separated by [hdr_spec,hdr_spec,hdr_spec]
        hdr_spec='=='
        % Data starts from the line next to [hdr_spec,end_header,hdr_spec]
        end_header='Data'
        % Columns are separated by this symbol (space-tab by default)
        column_sep=' \t'
        % Comments start from this symbol
        comment_sep='%'
        line_sep='\r\n'
        % Limit for column padding. Variables which take more space than
        % this limit are ignored when calculating the padding length.
        pad_lim=12
    end
    
    properties (Access=private)
        PropHandles %Used to store the handles of the dynamic properties
    end
    
    properties (Dependent=true)
        field_names
    end
    
    methods
        function [this,varargout]=MyMetadata(varargin)
            P=MyClassParser(this);

            if mod(length(varargin),2)==1
                % odd number of elements in varargin - interpret the first
                % element as file name and the rest as name-value pairs
                load_path=varargin{1};
                assert(ischar(load_path)&&isvector(load_path),...
                    '''file_name'' must be a vector of characters');
                processInputs(P, this, varargin{2:end});
            else
                % Parse varargin as a list of name-value pairs 
                processInputs(P, this, varargin{:});
                load_path=[];
            end
            
            this.PropHandles=struct();
            
            if ~isempty(load_path)
                varargout{1}=load(this, load_path);
            end
        end
        
        %Fields are added using this command. The field is a property of
        %the class, populated by the parameters with their values and
        %string specifications for later printing
        function addField(this, field_name)
            assert(isvarname(field_name),...
                'Field name must be a valid MATLAB variable name.');
            assert(~ismember(field_name, this.field_names),...
                ['Field with name ',field_name,' already exists.']);
            
            this.PropHandles.(field_name)=addprop(this,field_name);
            this.PropHandles.(field_name).SetAccess='protected';
            % Dynamic properties must not be copyable, copying of
            % MyMetadata objects is handled by dedicated overloaded method
            this.PropHandles.(field_name).NonCopyable=true;
            this.(field_name)=struct();
        end
        
        %Deletes a named field
        function deleteField(this, field_name)
            assert(isvarname(field_name),...
                'Field name must be a valid MATLAB variable name.');
            assert(ismember(field_name,this.field_names),...
                ['Attemped to delete field ''',field_name ...
                ,''' that does not exist.']);
            % Delete dynamic property from the class
            delete(this.PropHandles.(field_name));
            % Erase entry in PropHandles
            this.PropHandles=rmfield(this.PropHandles,field_name);
        end
        
        %Clears the object of all fields
        function clearFields(this)
            cellfun(@(x) deleteField(this, x), this.field_names)
        end
        
        
        % Copy all the fields of another Metadata object to this object
        function addMetadata(this, Metadata)
           assert(isa(Metadata,'MyMetadata'),...
               'Input must be of class MyMetadata, current input is %s',...
               class(Metadata));
           assert(~any(ismember(this.field_names,Metadata.field_names)),...
               ['The metadata being added contain fields with the same ',...
               'name. This conflict must be resolved before adding'])
           for i=1:length(Metadata.field_names)
               fn=Metadata.field_names{i};
               addField(this,fn);
               param_names=fieldnames(Metadata.(fn));
               cellfun(@(x) addParam(this,fn,x,Metadata.(fn).(x).value,...
                   'fmt_spec', Metadata.(fn).(x).fmt_spec,...
                   'comment', Metadata.(fn).(x).comment),...
                   param_names);
           end
        end
        
        %Adds a parameter to a specified field. The field must be created
        %first.
        function addParam(this, field_name, param_name, value, varargin)
            assert(ischar(field_name),'Field name must be a char');
            assert(isprop(this,field_name),...
                '%s is not a field, use addField to add it',param_name);
            assert(ischar(param_name),'Parameter name must be a char');
            
            p=inputParser();
            % Format specifier for printing the value
            addParameter(p,'fmt_spec','',@ischar);
            % Comment to be added to the line
            addParameter(p,'comment','',@ischar);
            addParameter(p,'SubStruct',struct('type',{},'subs',{}),...
                @isstruct)
            parse(p,varargin{:});
            
            S=p.Results.SubStruct;
            comment=p.Results.comment;
            
            %Making sure that the comment does not
            %contain new line or carriage return characters, which would
            %mess up formating when saving metadata
            
            newline_smb={sprintf('\n'),sprintf('\r')}; %#ok<SPRINTFN>
            
            if contains(comment, newline_smb)
                warning(['Comment string for ''%s'' must not contain ',...
                    '''\\n'' and ''\\r'' symbols, replacing them ',...
                    'with space.'], param_name);
                comment=replace(comment, newline_smb,' ');
            end
            
            this.(field_name).(param_name).comment=comment;
            
            if isempty(S)
                % Assign value directly
                this.(field_name).(param_name).value=value;
            else
                % Assign using subref structure
                tmp=feval([class(value),'.empty']);
                this.(field_name).(param_name).value=subsasgn(tmp,S,value);
            end
            
            this.(field_name).(param_name).fmt_spec=p.Results.fmt_spec;
        end
        
        function save(this, filename, varargin)
            createFile(filename, varargin{:});
            for i=1:length(this.field_names)
                printField(this, this.field_names{i}, filename);
            end
            printEndMarker(this, filename);
        end
        
        function printField(this, field_name, filename, varargin)
            %Takes optional inputs
            p=inputParser();
            addParameter(p,'title',field_name);
            parse(p,varargin{:});
            title_str=p.Results.title;
            
            ParStruct=this.(field_name);
            
            %Compose the list of parameter names expanded over subscripts
            %except for those which are already character arrays
            par_names=fieldnames(ParStruct);
            
            %Expand parameters over subscripts, except for the character
            %arrays
            exp_par_names=cell(1, length(par_names));
            maxnmarr=zeros(1, length(par_names));
            for i=1:length(par_names)
                tmpval=ParStruct.(par_names{i}).value;
                exp_par_names{i}=printSubs(tmpval, ...
                    'own_name', par_names{i}, ...
                    'expansion_test',@(y) ~ischar(y));
                
                %Max name length for this parameter including subscripts
                maxnmarr(i)=max(cellfun(@(x) length(x), exp_par_names{i}));
            end
            
            %Calculate width of the name column
            name_pad_length=min(max(maxnmarr), this.pad_lim);
            
            %Compose list of parameter values converted to char strings
            par_strs=cell(1, length(par_names));
            %Width of the values column will be the maximum parameter
            %string width
            val_pad_length=0;
            for i=1:length(par_names)
                TmpPar=ParStruct.(par_names{i});
                for j=1:length(exp_par_names{i})
                    tmpnm=exp_par_names{i}{j};
                    TmpS=str2substruct(tmpnm);
                    if isempty(TmpS)
                        tmpval=TmpPar.value;
                    else
                        tmpval=subsref(TmpPar.value, TmpS);
                    end
                    
                    %Do check to detect unsupported data type
                    if ischar(tmpval)&&~isvector(tmpval)&&~isempty(tmpval)
                        warning(['Argument ''%s'' is a multi-dimensional ',...
                            'character array. It will be converted to ',...
                            'single string during saving. Use cell',...
                            'arrays to save data as a set of separate ',...
                            'strings.'],tmpnm)
                        % Flatten
                        tmpval=tmpval(:);
                    end
                    
                    %Check for new line symbols in strings
                    if (ischar(tmpval)||isstring(tmpval)) && ...
                            any(ismember({newline,sprintf('\r')},tmpval))
                        warning(['String value must not contain ',...
                            '''\\n'' and ''\\r'' symbols, replacing them ',...
                            'with '' ''']);
                        tmpval=replace(tmpval,{newline,sprintf('\r')},' ');
                    end
                    
                    if isempty(TmpPar.fmt_spec)
                        % Convert to string with format specifier
                        % extracted from the varaible calss
                        par_strs{i}{j}=var2str(tmpval);
                    else
                        par_strs{i}{j}=sprintf(TmpPar.fmt_spec, tmpval);
                    end
                    % Find maximum length to determine the colum width, 
                    % but, for beauty, do not account for variables with 
                    % excessively long value strings
                    tmplen=length(par_strs{i});
                    if (val_pad_length<tmplen)&&(tmplen<=this.pad_lim)
                        val_pad_length=tmplen;
                    end
                end
            end
            
            fileID=fopen(filename,'a');
            %Prints the header separator
            fprintf(fileID,[this.hdr_spec, title_str,...
                this.hdr_spec, this.line_sep]);
            
            cs=this.column_sep;
            ls=this.line_sep;
            data_fmt_spec=[sprintf('%%-%is',name_pad_length),...
                    cs, sprintf('%%-%is',val_pad_length)];
            
            for i=1:length(par_names)
                %Capitalize first letter of comment
                if ~isempty(ParStruct.(par_names{i}).comment)
                    fmt_comment=[this.comment_sep,' '...
                        upper(ParStruct.(par_names{i}).comment(1)),...
                        ParStruct.(par_names{i}).comment(2:end)];
                else
                    fmt_comment='';
                end
                
                for j=1:length(exp_par_names{i})
                    if j==1
                        % Print comment in the first line
                        fprintf(fileID, [data_fmt_spec,cs,'%s',ls],...
                            exp_par_names{i}{j},par_strs{i}{j},fmt_comment);
                    else
                        fprintf(fileID, [data_fmt_spec,ls],...
                            exp_par_names{i}{j}, par_strs{i}{j});
                    end
                end
            end
            
            %Prints an extra line separator at the end
            fprintf(fileID, ls);
            fclose(fileID);
        end
        
        %Print terminator that separates header from data
        function printEndMarker(this, filename)
            fileID=fopen(filename,'a');
            fprintf(fileID,...
                [this.hdr_spec, this.end_header, ...
                this.hdr_spec, this.line_sep]);
            fclose(fileID);
        end
        
        %Adds time header
        %Second optional argument is the name of the field, i.e 
        %addTimeField(this, 'TimeField')
        function addTimeField(this, t_field_name)
            if nargin()>1
                assert(ischar(t_field_name)&&isvector(t_field_name),...
                    'Time field name must be a character vector')
            else
                t_field_name='Time';
            end
            
            if ismember(t_field_name, this.field_names)
                deleteField(this, t_field_name)
            end
            
            dv=datevec(datetime('now'));
            addField(this,t_field_name);
            addParam(this,t_field_name,'Year',dv(1),'fmt_spec','%i');
            addParam(this,t_field_name,'Month',dv(2),'fmt_spec','%i');
            addParam(this,t_field_name,'Day',dv(3),'fmt_spec','%i');
            addParam(this,t_field_name,'Hour',dv(4),'fmt_spec','%i');
            addParam(this,t_field_name,'Minute',dv(5),'fmt_spec','%i');
            addParam(this,t_field_name,'Second',...
                floor(dv(6)),'fmt_spec','%i');
            addParam(this,t_field_name,'Millisecond',...
                round(1000*(dv(6)-floor(dv(6)))),'fmt_spec','%i');
        end
        
        function n_end_header=load(this, filename)
            %Before we load, we clear all existing fields
            clearFields(this);
            
            fileID=fopen(filename,'r');
            
            title_exp=[this.hdr_spec,'(\w.*)',this.hdr_spec];
            
            %Loop initialization
            line_no=0;
            curr_title='';
            
            %Loop continues until we reach the next header or we reach
            %the end of the file
            while ~feof(fileID)
                line_no=line_no+1;
                %Grabs the current line
                curr_line=fgetl(fileID);
                %Gives an error if the file is empty, i.e. fgetl returns -1
                if curr_line==-1 
                    error('Tried to read empty file. Aborting.')
                end
                %Skips if current line is empty
                if isempty(curr_line)
                    continue
                end
                
                title_token=regexp(curr_line,title_exp,'once','tokens');
                %If we find a title, first check if it is the specified
                %end header. Then change the title if a title was found, 
                %then if no title was found, put the data under the current 
                %title.
                if ismember(this.end_header, title_token)
                    break
                elseif ~isempty(title_token)
                    % Apply genvarname for sefety in case the title string 
                    % is not a proper variable name 
                    curr_title=genvarname(title_token{1});
                    addField(this, curr_title);
                %This runs if there was no match for the header regular
                %expression, i.e. the current line is not a filed 
                %separator, and the current line is not empty. We then 
                %add this line to the current field (curr_title), possibly
                %iterating over the parameter subscripts.
                elseif ~isempty(curr_title)
                    % First separate the comment if present
                    tmp=regexp(curr_line,this.comment_sep,'split','once');
                    if length(tmp)>1
                        % the line has comment
                        comment_str=tmp{2};
                    else
                        comment_str='';
                    end
                    % Then process name-value pair. Regard everything after
                    % the first column separator as value.
                    tmp=regexp(tmp{1},this.column_sep,'split','once');
                    
                    if length(tmp)<2
                        % Ignore the line if a name-value pair is not found
                        continue
                    else
                        % Attempt convertion of value to number
                        val=str2doubleHedged(strtrim(tmp{2}));
                    end
                    
                    % Infer the variable name and subscript reference
                    try
                        [S, name]=str2substruct(strtrim(tmp{1}));
                    catch
                        name='';
                    end
                    
                    if isempty(name)
                        % Ignore the line if variable name is not missing
                        continue
                    elseif ismember(name, fieldnames(this.(curr_title)))
                        % If the variable name already presents among
                        % parameters, add new subscript value
                        this.(curr_title).(name).value= ...
                            subsasgn(this.(curr_title).(name).value,S,val);
                    else
                        % Add new parameter with comment
                        addParam(this, curr_title, name, val,...
                            'SubStruct', S, 'comment', comment_str);
                    end
                end
            end
            fclose(fileID);
            if isempty(this.field_names)
                warning('No metadata found, continuing without metadata.')
                n_end_header=1;
            else
                n_end_header=line_no;
            end
        end

        % Need a custom copy method as the one provided by 
        % matlab.mixin.Copyable does not re-create the handles of dynamic
        % properties stored in this.PropHandles
        function NewMet=copy(this)
            NewMet=MyMetadata();
            Mc=metaclass(NewMet);
            
            % Copy static public non-dependent properties
            for i=1:length(Mc.PropertyList)
                TmpProp=Mc.PropertyList(i);
                if strcmpi(TmpProp.GetAccess,'public') && ...
                        strcmpi(TmpProp.SetAccess,'public') && ...
                        ~TmpProp.Dependent
                    NewMet.(TmpProp.Name)=this.(TmpProp.Name);
                end
            end
            
            % Copy dynamic properties
            addMetadata(NewMet, this);
        end
    end
    
    
    %% Set and Get methods
    
    methods
        function field_names=get.field_names(this)
            field_names=fieldnames(this.PropHandles);
        end
        
    end
end