% get the IP addresses of this computer on local networks
function ip_list = getLocalIP()
    % Regex to match IP address, e.g 192.168.1.8
    % Each of the 4 blocks match dot-separated numbers and read as
    % ('25x', where x=0 to 5) or ('2xy' where x=0 to 4 and y=0 to 9) or
    % (zyx where z=0,1 or nothing; y=0 to 9; x=0 to 9 or nothing)
    % The 4 blocks are peceeded and followed by non-numeric characters 
    ip_regex = ['(\D)',...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.',...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.',...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.',...
        '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\D)'];
    instr_info = instrhwinfo('tcpip');
    ip_list = cell(1,length(instr_info.LocalHost));
    for i=1:length(instr_info.LocalHost)
        tmp_ip=regexp([' ',instr_info.LocalHost{i},' '],ip_regex,'match');
        if length(tmp_ip)>=1
            % if a match is found, assign it to the output disregarding the
            % first and the last separating characters
            ip_list{i}=tmp_ip{1}(2:end-1);
            if length(tmp_ip)>1
                warning('Multiple IP''s are matched by regex')
            end
        else
            ip_list{i}='';
        end
    end
    % Discard all the empty cells 
    ip_list = ip_list(~cellfun(@isempty,ip_list));
end

