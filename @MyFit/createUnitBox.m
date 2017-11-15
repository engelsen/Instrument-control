function createUnitDisp(this, bg_color, h_parent,name)
hbox_str=sprintf('%sDispHBox',name);
this.Gui.(hbox_str)=uix.HBox('Parent',h_parent,...
    'BackgroundColor',bg_color);
this.Gui.(sprintf('%sNameVBox',name))=uix.VBox('Parent',this.Gui.(hbox_str));
this.Gui.(sprintf('%sEditVBox',name))=uix.VBox('Parent',this.Gui.(hbox_str));
set(this.Gui.(hbox_str),'Widths',[-4,-2]);

end