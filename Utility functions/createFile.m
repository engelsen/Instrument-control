function write_flag=createFile(save_dir,fullfilename,overwrite_flag)
    write_flag=true;
    
    %Creates save directory if it does not exist
    if ~exist(save_dir,'dir')
        mkdir(save_dir)
    end

    if exist(fullfilename,'file') && ~overwrite_flag
        switch questdlg('Would you like to overwrite?',...
                'File already exists', 'Yes', 'No', 'No')
            case 'Yes'
                fprintf('Overwriting file at %s\n',fullfilename);
            otherwise
                warning('No file written as %s already exists',...
                    fullfilename);
                write_flag=false;
                return
        end
    end

    %Creates the file
    fileID=fopen(fullfilename,'w');
    fclose(fileID);

    %MATLAB returns -1 for the fileID if the file could not be
    %opened
    if fileID==-1
        errordlg(sprintf('File %s could not be created.',...
            fullfilename),'File error');
        write_flag=false;
        return
    end
end