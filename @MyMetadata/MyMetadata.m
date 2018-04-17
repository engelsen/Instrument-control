classdef MyMetadata < dynamicprops 
    properties
        uid;
        hdr_spec;
        field_names;
    end
    
    methods
        function this=MyMetadata(varargin)
            p=inputParser;
            addParameter(p,'uid',genUid())
            addParameter(p,'hdr_spec','==');
            parse(p,varargin{:});
            
            this.uid=p.Results.uid;
            this.hdr_spec=p.Results.hdr_spec;
            this.field_names={};
        end
        
        %Fields are added using this command. The field is a property of
        %the class, populated by the parameters with their values and
        %string specifications for later printing
        function addField(this, field_name)
            assert(ischar(field_name),'Field name must be a char');
            addprop(this,field_name);
            this.(field_name)=struct();
            this.field_names{end+1}=field_name;
        end
        
        function deleteField(this, field_name)
            delete(this.(field_name));
            ind=strcmp(this.field_names,field_name);
            this.field_names{ind}=[];
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
    end
end