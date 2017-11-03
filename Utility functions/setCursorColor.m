function setCursorColor(crsobj,color)
set(crsobj.TopHandle,'MarkerFaceColor',color);
set(crsobj.BottomHandle,'MarkerFaceColor',color);
set(crsobj,'CursorLineColor',color);
end