classdef MyMetadata < dynamicprops & matlab.mixin.Copyable
    properties
        hdr_spec
        column_sep
        comment_sep % comments start from this symbol
    end
    
    properties (Access=private)
        PropHandles %Used to store the handles of the dynamic properties
    end
    
    properties (Dependent=true)
        field_names
    end
    
    methods
        function [this,varargout]=MyMetadata(varargin)
            p=inputParser;
            addParameter(p,'hdr_spec','==',@ischar);
            addParameter(p,'load_path','',@ischar);
            addParameter(p,'end_header','Data',@ischar);
            addParameter(p,'column_sep',' \t',@ischar);
            appParameter(p,'comment_sep','%',@ischar);
            parse(p,varargin{:});
            
            this.hdr_spec=p.Results.hdr_spec;
            this.column_sep=p.Results.column_sep;
            this.comment_sep=p.Results.comment_sep;
            this.PropHandles=struct();
            
            if ~isempty(p.Results.load_path)
                varargout{1}=readHeaders(this,p.Results.load_path,...
                    'end_header',p.Results.end_header);
            end
        end
        
        %Fields are added using this command. The field is a property of
        %the class, populated by the parameters with their values and
        %string specifications for later printing
        function addField(this, field_name)
            assert(isvarname(field_name),...
                'Field name must be a valid MATLAB variable name.');
            this.PropHandles.(field_name)=addprop(this,field_name);
            this.PropHandles.(field_name).SetAccess='protected';
            this.PropHandles.(field_name).NonCopyable=false;
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
        
%         %This function adds a structure to a field of a given name. The
%         %field must be created before this can be used
%         function addStructToField(this, field_name, input_struct)
%             %Input checks
%             assert(ischar(field_name),'Field name must be a char');
%             assert(isprop(this,field_name),...
%                 '%s is not a field, use addField to add it',field_name);
%             assert(isa(input_struct,'struct'),...
%                 ['The input_struct input must be a struct.',...
%                 'Currently it is a %s'],class(input_struct))
%             
%             %Adds the parameters specified in the input struct.
%             param_names=fieldnames(input_struct);
%             for i=1:length(param_names)
%                 tmp=input_struct.(param_names{i});
%                 addParam(this,field_name, ...
%                     param_names{i},tmp.value,tmp.fmt_spec);
%             end
%         end
        
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
        function addParam(this, field_name, name, value, varargin)
            assert(ischar(field_name),'Field name must be a char');
            assert(isprop(this,field_name),...
                '%s is not a field, use addField to add it',name);
            assert(ischar(name),'Parameter name must be a char');
            assert(ischar(fmt_spec),'String spec must be a char');
            
            p=inputParser();
            % Format specifier for printing the value
            addParameter(p,'fmt_spec','',@ischar);
            % Comment to be added to the line
            addParameter(p,'comment','',@ischar);
            parse(p,varargin{:});
            
            %Adds the field
            this.(field_name).(name).value=value;
            this.(field_name).(name).fmt_spec=p.Results.fmt_spec;
            this.(field_name).(name).comment=p.Results.comment;
        end
        
        function writeAllHeaders(this,fullfilename)
            addTimeHeader(this);
            for i=1:length(this.field_names)
                writeHeader(this, fullfilename, this.field_names{i});
            end
        end
        
        function writeHeader(this, fullfilename, field_name, varargin)
            %Takes optional inputs
            p=inputParser;
            addParameter(p,'title',field_name);
            parse(p,varargin{:});
            title_str=p.Results.title;
            
            ParamStruct=this.(field_name);
            param_names=fieldnames(ParamStruct);
            %width of the name column
            name_pad_length=max(cellfun(@(x) length(x), param_names));
            
            % Make list of parameter values converted to strings
            par_strs=cell(1,length(param_names));
            for i=1:length(param_names)
                TmpParam=ParamStruct.(param_names{i});
                if isempty(TmpParam.fmt_spec)
                    % Convert to string with format specifier
                    % extracted from the varaible calss
                    par_strs{i}=var2str(TmpParam.value);
                else
                    par_strs{i}=sprintf(TmpParam.fmt_spec, TmpParam.value);
                end
            end
            %width of the values column
            val_pad_length=max(cellfun(@(x) length(x), par_strs));
            
            fileID=fopen(fullfilename,'a');
            %Prints the header
            fprintf(fileID,'%s%s%s\r\n', this.hdr_spec, title_str,...
                this.hdr_spec);
            
            for i=1:length(param_names)
                %Capitalize first letter of parameter name and comment
                fmt_name=[upper(param_names{i}(1)),param_names{i}(2:end)];
                if ~isempty(ParamStruct.(param_names{i}).comment)
                    fmt_comment=[this.comment_sep,...
                        Upper(ParamStruct.(param_names{i}).comment(1)),...
                        ParamStruct.(param_names{i}).comment(2:end)];
                else
                    fmt_comment='';
                end
                
                print_spec=[sprintf('%%-%is',name_pad_length),...
                    this.column_sep,...
                    sprintf('%%-%is',val_pad_length),...
                    this.column_sep,'%s\r\n'];

                fprintf(fileID, print_spec, fmt_name, par_strs{i},...
                    fmt_comment);
            end
            
            %Prints an extra line at the end
            fprintf(fileID,'\r\n');
            fclose(fileID);
        end
        
        %Adds time header
        function addTimeHeader(this)
            if isprop(this,'Time')
                deleteField(this,'Time')
            end
            dv=datevec(datetime('now'));
            addField(this,'Time');
            addParam(this,'Time','Year',dv(1),'fmt_spec','%i');
            addParam(this,'Time','Month',dv(2),'fmt_spec','%i');
            addParam(this,'Time','Day',dv(3),'fmt_spec','%i');
            addParam(this,'Time','Hour',dv(4),'fmt_spec','%i');
            addParam(this,'Time','Minute',dv(5),'fmt_spec','%i');
            addParam(this,'Time','Second',floor(dv(6)),'fmt_spec','%i');
            addParam(this,'Time','Millisecond',...
                round(1000*(dv(6)-floor(dv(6)))),'fmt_spec','%i');
        end
        
        function n_end_header=readHeaders(this, fullfilename, varargin)
            %Before we load, we clear all existing fields
            clearFields(this);
            
            fileID=fopen(fullfilename);
            
            title_exp=[this.hdr_spec,'(\w.*)',this.hdr_spec];
            
            %Loop initialization
            line_no=0;
            curr_title='';
            
            %Loop continues until we reach the next header or we reach the end of
            %the file
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
                
                res_str=regexp(curr_line,title_exp,'once','tokens');
                %If we find a title, first check if it is the specified end header.
                %Then change the title if a title was found, then if no title was
                %found, put the data under the current title.
                if ~ismember(res_str,end_header)
                    break
                elseif ~isempty(res_str)
                    curr_title=res_str{1};
                    %Capitalizes the letter after a space
                    ind=regexp([' ' curr_title],'(?<=\s+)\S','start')-1;
                    curr_title(ind)=upper(curr_title(ind));
                    %Removes spaces
                    curr_title=curr_title(~isspace(curr_title));
                    addField(this,curr_title);
                %This runs if there was no match for the regular
                %expression, i.e. the current line is not a header, and the
                %current line is not empty. We then add this line to the
                %current field (curr_title).
                elseif ~isempty(curr_title)
                    tmp=strsplit(curr_line, this.column_sep,...
                        'CollapseDelimiters',true);
                    %Remove leading and trailing spaces
                    tmp=strtrim(tmp);
                    val=str2doubleHedged(tmp{2});
                    comment_str=sscanf(tmp{3},[this.comment_sep,'%s']);
                    %Store retrieved value
                    addParam(this,curr_title,lower(tmp{1}),val,...
                        'comment',comment_str);
                end
            end
            
            if isempty(this.field_names)
                warning('No header found, continuing without header')
                n_end_header=1;
            else
                n_end_header=line_no;
            end
        end
        
    end
    
    methods
        function field_names=get.field_names(this)
            field_names=fieldnames(this.PropHandles);
        end
        
    end
end