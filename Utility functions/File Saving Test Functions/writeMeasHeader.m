function writeMeasHeader(fileID, title_str, param_struct,hdr_spec)
    
    if isfield(param_struct,'str_spec')
        str_spec=param_struct.str_spec;
        param_struct=rmfield(param_struct,'str_spec');
    else
        warning('No str_spec provided, using char')
        str_spec=cell(1,length(fieldnames(param_struct)));
        str_spec(:)={'s'};
    end
    
    if length(str_spec)~=length(fieldnames(param_struct))
        error(['The number of string specifiers must equal the number of ',...
            'fields in the structure to be written. \nCurrently, the ',...
            'number of string specifiers is %d and the number of fields',...
            ' is %d'],length(str_spec),length(fieldnames(param_struct)));
    end
    
    %Prints the header
    fprintf(fileID,'%s%s%s\r\n',hdr_spec,title_str,hdr_spec);

    param_names=fieldnames(param_struct);
    %plus one to padding for beauty
    pad_length=max(cellfun(@(x) length(x), param_names))+1;

    for i=1:length(param_names)
        %Capitalize first letter of parameter name
        fmt_name=[upper(param_names{i}(1)),param_names{i}(2:end)];

        print_spec=sprintf('%%-%ds\t%%%s\r\n',pad_length,str_spec{i});
        fprintf(fileID,print_spec,fmt_name,param_struct.(param_names{i}));
    end

    %Prints an extra line at the end
    fprintf(fileID,'\r\n');
end