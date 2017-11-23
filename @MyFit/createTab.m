function createTab(this,tab_tag,bg_color, button_h)
tab_field=sprintf('%sTab',tab_tag);
%Creates a tab inside the user panel
this.Gui.(tab_field)=uix.Panel('Parent', this.Gui.TabPanel,...
    'Padding', 0, 'BackgroundColor',bg_color);

%Creates VBoxes for the quantities to be displayed
createUnitBox(this,bg_color,this.Gui.(tab_field),tab_tag);

%Creates boxes to show numbers and labels for quality factor, frequency and
%linewidth
names=fieldnames(this.UserGuiStruct.(tab_tag));
names(strcmp(names,'tab_title'))=[];
for i=1:length(names)
    createUnitDisp(this,...
        'BackgroundColor',bg_color,...
        'Tag',names{i},...
        'Parent',tab_tag,...
        'Title',this.UserGuiStruct.(tab_tag).(names{i}).title,...
        'Enable',this.UserGuiStruct.(tab_tag).(names{i}).enable_flag,...
        'init_val',this.UserGuiStruct.(tab_tag).(names{i}).init_val);
end
%Sets the heights of the edit boxes 
name_vbox=sprintf('%sNameVBox',tab_tag);
value_vbox=sprintf('%sEditVBox',tab_tag);

set(this.Gui.(name_vbox),'Heights',button_h*ones(1,length(names)));
set(this.Gui.(value_vbox),'Heights',button_h*ones(1,length(names)));
end