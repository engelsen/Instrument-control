function createTab(this,tab_tag,bg_color, button_h)
tab_field=sprintf('%sTab',tab_tag);
%Creates a tab inside the user panel
this.Gui.(tab_field)=uix.Panel('Parent', this.Gui.TabPanel,...
    'Padding', 0, 'BackgroundColor',bg_color);

%Creates VBoxes for the quantities to be displayed
createUnitBox(this,bg_color,this.Gui.(tab_field),tab_tag);

%Creates boxes to show numbers and labels for quality factor, frequency and
%linewidth
ind=structfun(@(x) strcmp(x.parent,tab_tag), this.UserGui.Fields);
names=fieldnames(this.UserGui.Fields);
names=names(ind);

for i=1:length(names)
    field=this.UserGui.Fields.(names{i});
    createUnitDisp(this,...
        'BackgroundColor',bg_color,...
        'Tag',names{i},...
        'Parent',tab_tag,...
        'Title',field.title,...
        'Enable',field.enable_flag,...
        'init_val',field.init_val/field.conv_factor);
end
%Sets the heights of the edit boxes 
name_vbox=sprintf('%sNameVBox',tab_tag);
value_vbox=sprintf('%sEditVBox',tab_tag);

set(this.Gui.(name_vbox),'Heights',button_h*ones(1,length(names)));
set(this.Gui.(value_vbox),'Heights',button_h*ones(1,length(names)));
end