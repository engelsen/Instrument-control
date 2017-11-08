%Initializes MyDaq Gui. Needs no inputs, but should be modified if you wish
%to change the callbacks etc.
function initGui(this)

%Close request function is set to delete function of the class
this.Gui.figure1.CloseRequestFcn=@(hObject,eventdata)...
    closeFigure(this, hObject, eventdata);
%Sets callback for the edit box of the base directory
this.Gui.BaseDir.Callback=@(hObject, eventdata)...
    baseDirCallback(this, hObject, eventdata);
%Sets callback for the session name edit box
this.Gui.SessionName.Callback=@(hObject, eventdata)...
    sessionNameCallback(this, hObject, eventdata);
%Sets callback for the file name edit box
this.Gui.FileName.Callback=@(hObject, eventdata) ...
    fileNameCallback(this, hObject,eventdata);
%Sets callback for the save data button
this.Gui.SaveData.Callback=@(hObject, eventdata) ...
    saveDataCallback(this, hObject,eventdata);
%Sets callback for the save ref button
this.Gui.SaveRef.Callback=@(hObject, eventdata)...
    saveRefCallback(this, hObject, eventdata);
%Sets callback for the show data button
this.Gui.ShowData.Callback=@(hObject, eventdata)...
    showDataCallback(this, hObject, eventdata);
%Sets callback for the show reference button
this.Gui.ShowRef.Callback=@(hObject, eventdata)...
    showRefCallback(this, hObject, eventdata);
%Sets callback for the data to reference button
this.Gui.DataToRef.Callback=@(hObject, eventdata)...
    dataToRefCallback(this, hObject, eventdata);
%Sets callback for the LogY button
this.Gui.LogY.Callback=@(hObject, eventdata) ...
    logYCallback(this, hObject, eventdata);
%Sets callback for the LogX button
this.Gui.LogX.Callback=@(hObject, eventdata)...
    logXCallback(this, hObject, eventdata);
%Sets callback for the data to background button
this.Gui.DataToBg.Callback=@(hObject, eventdata) ...
    dataToBgCallback(this, hObject,eventdata);
%Sets callback for the ref to background button
this.Gui.RefToBg.Callback=@(hObject, eventdata) ...
    refToBgCallback(this, hObject,eventdata);
%Sets callback for the clear background button
this.Gui.ClearBg.Callback=@(hObject, eventdata)...
    clearBgCallback(this, hObject,eventdata);
%Sets callback for the select trace popup menu
this.Gui.SelTrace.Callback=@(hObject,eventdata)...
    selTraceCallback(this, hObject,eventdata);
%Sets callback for the vertical cursor button
this.Gui.VertDataButton.Callback=@(hObject, eventdata)...
    cursorButtonCallback(this, hObject,eventdata);
%Sets callback for the horizontal cursors button
this.Gui.HorzDataButton.Callback=@(hObject, eventdata)...
    cursorButtonCallback(this, hObject,eventdata);
%Sets callback for the reference cursors button
this.Gui.VertRefButton.Callback=@(hObject, eventdata)...
    cursorButtonCallback(this, hObject,eventdata);
%Sets callback for the center cursors button
this.Gui.CenterCursors.Callback=@(hObject,eventdata)...
    centerCursorsCallback(this,hObject,eventdata);
%Sets callback for the center cursors button
this.Gui.CopyPlot.Callback=@(hObject,eventdata)...
    copyPlotCallback(this,hObject,eventdata);
%Sets callback for load trace button
this.Gui.LoadButton.Callback=@(hObject,eventdata)...
    loadDataCallback(this,hObject,eventdata);

%Initializes the AnalyzeMenu
this.Gui.AnalyzeMenu.Callback=@(hObject, eventdata)...
    analyzeMenuCallback(this, hObject,eventdata);
%List of available analysis routines
this.Gui.AnalyzeMenu.String={'Select a routine...',...
    'Linear Fit','Quadratic Fit','Exponential Fit',...
    'Gaussian Fit','Lorentzian Fit','Double Lorentzian Fit',...
    'g0 Calibration','Beta Calibration'};

%Initializes the InstrMenu
this.Gui.InstrMenu.Callback=@(hObject,eventdata) ...
    instrMenuCallback(this,hObject,eventdata);
end