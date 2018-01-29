function title_list = menuTitlesFromRunFiles(run_file_list)
    title_list = cell(length(run_file_list),1);
    for i=1:length(run_file_list)
        if isfield(run_file_list(i), 'menu_title')
            title_list{i} = run_file_list(i).menu_title;
        elseif isfield(run_file_list(i), 'name')
            title_list{i} = run_file_list.name;
        else
            title_list{i} = 'no name';
            warning('The following entry has no name field')
            disp(run_file_list(i))
        end
    end
end

