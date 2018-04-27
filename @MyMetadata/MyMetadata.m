classdef MyMetadata < dynamicprops 
    properties
        uid;
        hdr_spec;
    end
    
    properties (Access=private)
        DynamicProps;
    end
    
    properties (Dependent=true)
        field_names;
    end
    
    methods
        function [this,varargout]=MyMetadata(varargin)
            p=inputParser;
            addParameter(p,'uid',genUid())
            addParameter(p,'hdr_spec','==',@ischar);
            addParameter(p,'load_path','',@ischar);
            addParameter(p,'end_header','Data',@ischar);
            
            parse(p,varargin{:});
            
            this.uid=p.Results.uid;
            this.hdr_spec=p.Results.hdr_spec;
            this.DynamicProps=struct();
            
            if ~isempty(p.Results.load_path)
                varargout{1}=readHeaders(this,p.Results.load_path,...
                    'end_header',p.Results.end_header);
            end
        end
        
        %Fields are added using this command. The field is a property of
        %the class, populated by the parameters with their values and
        %string specifications for later printing
        function addField(this, field_name)
            assert(ischar(field_name),'Field name must be a char');
            this.DynamicProps.(field_name)=addprop(this,field_name);
            this.(field_name)=struct();
        end
        
        %Deletes a named field
        function deleteField(this, field_name)
            assert(ischar(field_name),'Field name must be a char')
            assert(ismember(field_name,this.field_names),...
                'Field name must be a valid property');
            delete(this.DynamicProps.(field_name));
            this.DynamicProps=rmfield(this.DynamicProps,field_name);
        end
        
        %Clears the object of all fields
        function clearFields(this)
            cellfun(@(x) deleteField(this, x), this.field_names)
        end
        
        %This function adds a structure to a field of a given name. The
        %field must be created before this can be used
        function addStructToField(this, field_name, input_struct)
            %Input checks
            assert(ischar(field_name),'Field name must be a char');
            assert(isprop(this,field_name),...
                '%s is not a field, use addField to add it',field_name);
            assert(isa(input_struct,'struct'),...
                ['The input_struct input must be a struct.',...
                'Currently it is a %s'],class(input_struct))
            
            %Adds the parameters specified in the input struct.
            param_names=fieldnames(input_struct);
            for i=1:length(param_names)
                tmp=input_struct.(param_names{i});
                addParam(this,field_name, ...
                    param_names{i},tmp.value,tmp.str_spec);
            end
        end
        
        %Adds a parameter to a specified field. The field must be created
        %first.
        function addParam(this, field_name, name, value, str_spec)
            assert(ischar(field_name),'Field name must be a char');
            assert(isprop(this,field_name),...
                '%s is not a field, use addField to add it',name);
            assert(ischar(name),'Parameter name must be a char');
            assert(ischar(str_spec),'String spec must be a char');
            
            %Adds the field
            this.(field_name).(name).value=value;
            this.(field_name).(name).str_spec=str_spec;
        end
        
        function writeAllHeaders(this,fullfilename)
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
            
            fileID=fopen(fullfilename,'a');
            %Prints the header
            fprintf(fileID,'%s%s%s\r\n',this.hdr_spec,title_str,this.hdr_spec);
            
            ParamStruct=this.(field_name);
            param_names=fieldnames(ParamStruct);
            %plus one to padding for beauty
            pad_length=max(cellfun(@(x) length(x), param_names))+1;
            
            for i=1:length(param_names)
                %Capitalize first letter of parameter name
                fmt_name=[upper(param_names{i}(1)),param_names{i}(2:end)];
                
                %Sets the string specifier for the parameter
                if isfield(ParamStruct.(param_names{i}),'str_spec')
                    str_spec=ParamStruct.(param_names{i}).str_spec;
                else
                    warning('No str_spec provided for %s, using char',param_names{i})
                    str_spec='%s';
                end
                
                print_spec=sprintf('%%-%ds\t%s\r\n',pad_length,str_spec);
                fprintf(fileID,print_spec,fmt_name,...
                    ParamStruct.(param_names{i}).value);
            end
            
            %Prints an extra line at the end
            fprintf(fileID,'\r\n');
            fclose(fileID);
        end
        
        function n_end_header=readHeaders(this, fullfilename, varargin)
            p=inputParser;
            addParameter(p,'end_header','Data')
            addParameter(p,'hdr_spec',this.hdr_spec);
            parse(p,varargin{:});
            
            end_header=p.Results.end_header;
            this.hdr_spec=p.Results.hdr_spec;
            
            %Before we load, we clear all fields
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
                if curr_line==-1; error('Tried to read empty file. Aborting.'); end
                %Skips if current line is empty
                if isempty(curr_line); continue; end
                
                res_str=regexp(curr_line,title_exp,'once','tokens');
                %If we find a title, first check if it is the specified end header.
                %Then change the title if a title was found, then if no title was
                %found, put the data under the current title.
                if ~isempty(res_str) && contains(res_str,end_header)
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
                    tmp=strsplit(curr_line,'\t','CollapseDelimiters',true);
                    %Remove spaces
                    tmp=cellfun(@(x) erase(x,' '), tmp,'UniformOutput',false);
                    [val,str_spec]=str2doubleHedged(tmp{2});
                    %Store retrieved value
                    addParam(this,curr_title,tmp{1},val,str_spec);
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
            field_names=fieldnames(this.DynamicProps);
        end
    end
end