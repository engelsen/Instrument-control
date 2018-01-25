% Pings all the IP addresses assuming the subnet mask 255.255.255.000
% Local IP is a string of dot-separated decimals like '192.168.1.8'
% Caution: very slow, use the 'ind' option for partial search
function rsc_list = findTcpipInstruments(local_ip, varargin)
    p=inputParser();
    addParameter(p,'ind',[1,254], @(x) validateattributes(x, {'numeric'},...
        {'integer','nondecreasing','>',1,'<',254}));
    addParameter(p,'visa_adaptor','ni',@ischar);
    parse(p,varargin{:});
    v_ad = p.Results.visa_adaptor;
            
    a = sscanf(local_ip,'%i.%i.%i.%i');
    rsc_list = {};
    % Do full search. 0 and 255 are not valid as host names
    disp('Found TCPIP-VISA instruments:');
    for i=p.Results.ind(1):p.Results.ind(2)
        ip = sprintf('%i.%i.%i.%i',a(1),a(2),a(3),i);
        rsc_name = sprintf('TCPIP0::%s::inst0::INSTR',ip);
        % Try to connect to the device and open it
        tmp_dev = visa(v_ad,rsc_name); %#ok<TNMLP>
        try
            fopen(tmp_dev);
            fclose(tmp_dev);
            % If the fopen operation was successful, add the IP to ip_list 
            rsc_list = [rsc_list,sprintf('visa(''%s'',''%s'');',...
                v_ad,rsc_name)];   %#ok<AGROW>
            disp(rsc_name);
        catch
            % If error - do nothing 
        end
        delete(tmp_dev);
    end
end

