% Function creates file, if necessary together with subdirectory, and shows
% a dialog if the file with such name already exisits
function file_created=createFile(fullfilename,varargin)
    p=inputParser();
    addRequired(p,'fullfilename',@ischar);
    addParameter(p,'overwrite',false,@islogical);
    parse(p,fullfilename,varargin{:});

    file_created=true;
    
    %Creates save directory if it does not exist
    [save_dir,~,~]=fileparts(fullfilename);
    if ~exist(save_dir,'dir')
        mkdir(save_dir)
    end
    
    if exist(fullfilename,'file') && ~p.Results.overwrite
        finfo=dir(fullfilename);
        if finfo.bytes~=0
            % File is not empty. Ask user what to do next.
            resp = yesnodlg( ...
                    'File already exists. Would you like to overwrite?',...
                    'File already exists', false);
            if resp
                fprintf('Overwriting file at %s\n',fullfilename);
            else
                warning('No file written as %s already exists',...
                        fullfilename);
                file_created=false;
                return
            end
        end
    end
    %Creates an empty file
    fileID=fopen(fullfilename,'w');
    fclose(fileID);

    %MATLAB returns -1 for the fileID if the file could not be
    %opened
    if fileID==-1
        errordlg(sprintf('File %s could not be created.',...
            fullfilename),'File error');
        file_created=false;
        return
    end
end