% Start a logger n random channels

function [Lg, GuiLg] = runRandLogger(varargin)
    p = inputParser();
    addParameter(p, 'channel_no', 2);
    parse(p, varargin{:});
    
    data_headers = cell(1, p.Results.channel_no);
    for i = 1:length(data_headers)
        data_headers{i} = ['Measurement' num2str(i)];
    end
    
    Lg = MyLogger('measFcn', @()rand(1, p.Results.channel_no), ...
        'log_opts', {'data_headers', data_headers});
    GuiLg = GuiLogger(Lg);
end

