% Give menu content based on the structure, returned by readRunFiles
function content = menuFromRunFiles(RunFiles, varargin)
    % varargin is made of tag-value pairs, so only those elements that have
    % the property tag for which .(tag)=value are selected for the output
    run_file_list = struct2cell(RunFiles);
    is_sel = cellfun(@(x) isfieldval(x, varargin{:}), run_file_list);
    
    run_file_list = run_file_list(is_sel);
    tag_list = cell(length(run_file_list),1);
    title_list = cell(length(run_file_list),1);
    
    for i=1:length(run_file_list)
        TmpRunFile = run_file_list{i};
        if isfield(TmpRunFile, 'name')
            tag_list{i} = TmpRunFile.name;
            if isfield(TmpRunFile, 'menu_title') &&...
                    ~isempty(TmpRunFile.menu_title)
                title_list{i} = TmpRunFile.menu_title;
            else 
                title_list{i} = TmpRunFile.name;
            end
        else
            title_list{i} = 'no_name';
            tag_list{i} = 'no_name';
            warning('The following entry has no name field')
            disp(run_file_list{i})
        end
    end
    
    content = struct();
    content.titles = title_list;
    content.tags = tag_list;
end

