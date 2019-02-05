% A table-based interface for editing structure field. The input structure
% is displayed as fieldname-value pairs in an editable table and the  
% modified values are returned as an output structure.

function OutS = tabledlg(InS, varargin)
    p=inputParser();
    addRequired(p,'InS', @(x)assert(isstruct(x), ...
        'Input argument must be structure'));
    addParameter(p, 'Name', '', @ischar); % Figure name to display
    parse(p, InS, varargin{:});
    
    % Selected table row number is updated by callbacks
    sel_row=[];
    
    % Output structure is only assigned when 'Continue' button is pushed
    OutS=[];
    
    % Define geometry
    tbl_w=262;
    tbl_h=204;
    
    btn_w=50;
    btn_h=20;
    
    sps=10; % space between elements
    
    fig_w=tbl_w+btn_w+2*sps;
    fig_h=tbl_h;
    R=groot();
    % Display the figure window in the center of the screen
    fig_x=R.ScreenSize(3)/2-fig_w/2;
    fig_y=R.ScreenSize(4)/2-fig_h/2;
    
    F = figure('MenuBar','none', ...
        'Name',p.Results.Name, ...
        'NumberTitle','off', ...
        'Resize','off', ...
        'Position',[fig_x,fig_y,fig_w,fig_h]);
    
    uicontrol(F, 'Style', 'pushbutton', 'String', 'Add',...
        'Position', [tbl_w+sps, 2*sps+btn_h, btn_w, btn_h], ...
        'Callback', @addButtonCallback);
    uicontrol(F, 'Style', 'pushbutton', 'String', 'Delete',...
        'Position', [tbl_w+sps, sps+(sps+btn_h)*2, btn_w, btn_h], ...
        'Callback', @deleteButtonCallback);
    uicontrol(F, 'Style', 'pushbutton', 'String', 'Continue',...
        'Position', [tbl_w+sps, sps, btn_w, btn_h], ...
        'Callback', @continueButtonCallback);
    
    dat=[fieldnames(InS), cellfun(@(x)var2str(x), ...
        struct2cell(InS),'UniformOutput', false)];
    T = uitable(F, 'Data', dat, ...
        'ColumnWidth',{tbl_w/2-15, tbl_w/2-15}, ...
        'ColumnName',{'parameter', 'value'}, ...
        'Position',[0 0 tbl_w tbl_h], 'ColumnEditable', true, ...
        'CellSelectionCallback', @selectionCallback, ...
        'CellEditCallback', @editCallback);
    
    % Wait until the figure f is deleted
    uiwait(F);
    
    
    %% Callbacks
    
    function selectionCallback(~, EventData)
        if ~isempty(EventData.Indices)
            sel_row = EventData.Indices(1);
        end
    end
    
    % Table edited, makes sure that the first column only contains valid 
    % and unique Matlab variable names, which is necessary to convert the
    % table content to structure
    function editCallback(~, EventData)
        row=EventData.Indices(1);
        col=EventData.Indices(2);
        if col==1
            [newval,mod]=matlab.lang.makeValidName(T.Data{row,1});
            if mod
                warning(['Parameter name must be a valid Matlab ' ...
                    'variable name']);
            end
            [newval,mod]=matlab.lang.makeUniqueStrings(newval, ...
                [T.Data(1:row-1,1);T.Data(row+1:end,1)]);
            if mod
                warning('Parameter name must be unique');
            end
            T.Data{row,1}=newval;
        end
    end

    function continueButtonCallback(~,~)
        [nrows, ~]=size(T.Data);
        for i=1:nrows
            % Try converting values to numbers
            OutS.(T.Data{i,1})=str2doubleHedged(T.Data{i,2});
        end
        delete(F);
    end
    
    % Add new entry
    function addButtonCallback(~, ~)
        % Generate dummy parameter name 
        parname=matlab.lang.makeUniqueStrings('par', T.Data(:,1));
        T.Data=[T.Data;{parname,''}];
    end

    % Delete selected entry
    function deleteButtonCallback(~, ~)
        if ~isempty(sel_row)
            T.Data(sel_row,:)=[];
            sel_row=[];
        end
    end
end

