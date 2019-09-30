function createUnitDisp(this,varargin)
p=inputParser;
addParameter(p,'BackgroundColor','w');
addParameter(p,'Tag','Placeholder',@ischar);
addParameter(p,'Parent','Placeholder',@ischar);
addParameter(p,'Title','Placeholder',@ischar);
addParameter(p,'Enable','on',@ischar);
addParameter(p,'init_val',1,@isnumeric);
parse(p,varargin{:});

tag=p.Results.Tag;
vbox_name=sprintf('%sNameVBox',p.Results.Parent);
vbox_edit=sprintf('%sEditVBox',p.Results.Parent);
label_name=sprintf('%sLabel',tag);
value_name=sprintf('%sEdit',tag);

this.Gui.(label_name)=annotation(this.Gui.(vbox_name),...
    'textbox',[0.5,0.5,0.3,0.3],...
    'String',p.Results.Title,'Units','Normalized',...
    'HorizontalAlignment','Left','VerticalAlignment','middle',...
    'FontSize',10,'BackgroundColor',p.Results.BackgroundColor);
this.Gui.(value_name)=uicontrol('Parent',this.Gui.(vbox_edit),...
    'Style','edit','String',num2str(p.Results.init_val),...
    'HorizontalAlignment','Right',...
    'FontSize',10,'Enable',p.Results.Enable);

if ~isempty(this.UserGui.Fields.(tag).Callback)
    this.Gui.(value_name).Callback=this.UserGui.Fields.(tag).Callback;
end

end