function [Headers,line_no]=readAllMeasHeaders(file_path, hdr_spec,end_header)
    if ~exist('end_header', 'var'); end_header='Data'; end
        fileID=fopen(file_path);
    
    title_exp=[hdr_spec,'(\w.*)',hdr_spec];
    
    %Loop initialization
    line_no=0;
    
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
            Headers.(curr_title)=struct();
        elseif ~isempty(curr_title) 
            tmp=strsplit(curr_line,'\t','CollapseDelimiters',true);
            %Remove spaces
            tmp=cellfun(@(x) erase(x,' '), tmp,'UniformOutput',false);
            %Store retrieved value
            Headers.(curr_title).(tmp{1})=str2doubleHedged(tmp{2});
        end
    end
end
