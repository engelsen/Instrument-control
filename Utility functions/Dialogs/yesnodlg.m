% Analog of questdlg which runs more stable 

function bool = yesnodlg(quest,title,default)
    assert(islogical(default), 'Default value must be of logical type')
    
    % Define geometry 
    btn_w=56;
    btn_h=22;
    
    sps=10; % spacing between elements
    
    fig_w=2*btn_w+3*sps;
    fig_h=btn_h+2*sps;
    R=groot();
    % Display the figure window in the center of the screen
    fig_x=R.ScreenSize(3)/2-fig_w/2;
    fig_y=R.ScreenSize(4)/2-fig_h/2;
    
    F = figure('MenuBar','none', ...
        'Name',title, ...
        'NumberTitle','off', ...
        'Resize','off', ...
        'KeyPressFcn', @(x,y)figKeyPressCallback(x,y), ...
        'Position',[fig_x,fig_y,fig_w,fig_h]);
    
    Txt=uicontrol(F, 'Style', 'text', 'String', quest, 'Visible', 'off');
    
    % Resize the figure to accomodate text
    F.Position(3)=max(fig_w, Txt.Extent(3)+2*sps);
    F.Position(4)=Txt.Extent(4)+3*sps+btn_h;
    
    % Redraw the text and add buttons
    uicontrol(F, 'Style', 'text', 'String', quest, ...
        'Position', [sps, 2*sps+ btn_h, Txt.Extent(3), Txt.Extent(4)]);
    delete(Txt);
    
    uicontrol(F, 'Style', 'pushbutton', 'String', 'Yes', ...
        'Position', [F.Position(3)/2-sps/2-btn_w, sps, btn_w, btn_h], ...
        'KeyPressFcn', @(x,y)btnKeyPressCallback(x,y), ...
        'Callback', @yesBtnCallback);
    NoBtn=uicontrol(F, 'Style', 'pushbutton', 'String', 'No', ...
        'Position', [F.Position(3)/2+sps/2, sps, btn_w, btn_h], ...
        'KeyPressFcn', @(x,y)btnKeyPressCallback(x,y), ...
        'Callback', @noBtnCallback);
    
    uicontrol(NoBtn) % Set selection to the No button
    
    bool=default;
    
    % Wait until the figure is deleted
    uiwait(F);
    
    function yesBtnCallback(~, ~)
        bool=true;
        delete(F);
    end
    function noBtnCallback(~, ~)
        bool=false;
        delete(F);
    end

    function btnKeyPressCallback(Btn, EventData)  
        switch(EventData.Key)
            case {'return'}
                if strcmpi(Btn.String,'yes')
                    bool=true;
                else
                    bool=false;
                end
                delete(F);
            case 'escape'
                bool=false;
                delete(F);
        end
    end
    function figKeyPressCallback(~, EventData)  
        switch(EventData.Key)
            case 'escape'
                bool=false;
                delete(F);
        end
    end
end

