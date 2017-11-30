classdef MyDaq < handle
    properties
        %Contains GUI handles
        Gui;
        %Contains Reference trace (MyTrace object)
        Ref=MyTrace();
        %Contains Data trace (MyTrace object)
        Data=MyTrace();
        %Contains Background trace (MyTrace object)
        Background=MyTrace();
        %Struct containing available instruments
        InstrList=struct();
        %Struct containing MyInstrument objects 
        Instruments=struct()
        %Struct containing apps for interfacing with instruments
        InstrApps=struct();
        %Struct containing Cursor objects
        Cursors=struct();
        %Struct containing Cursor labels
        CrsLabels=struct();
        %Struct containing MyFit objects
        Fits=struct();
        %Input parser
        Parser;
        %Struct for listeners
        Listeners=struct();
        
        %Sets the colors of fits, data and reference
        fit_color='k';
        data_color='b';
        ref_color='r';
        bg_color='c';
        
        %Properties for saving files
        base_dir;
        session_name;
        file_name;
        
        %Flag for enabling the GUI
        enable_gui;
    end
    
    properties (Dependent=true)
        save_dir;
        main_plot;
        open_fits;
        open_instrs;
        open_crs;
        instr_tags;
        instr_names;
        savefile;
    end
    
    methods (Access=public)
        %% Class functions
        %Constructor function
        function this=MyDaq(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this);
            if this.enable_gui
                this.Gui=guihandles(eval('GuiDaq'));
                initGui(this);
                hold(this.main_plot,'on');
            end
            initDaq(this)
        end
        
        function delete(this)
            %Deletes the MyFit objects and their listeners
            cellfun(@(x) delete(this.Fits.(x)), this.open_fits);
            cellfun(@(x) deleteListeners(this,x), this.open_fits);
            
            %Deletes the MyInstrument objects and their listeners
            cellfun(@(x) delete(this.Instruments.(x)), this.open_instrs);
            cellfun(@(x) deleteListeners(this,x), this.open_instrs);
            
            if this.enable_gui
                this.Gui.figure1.CloseRequestFcn='';
                %Deletes the figure
                delete(this.Gui.figure1);
                %Removes the figure handle to prevent memory leaks
                this.Gui=[];
            end         
        end
    end
    
    methods (Access=private)
        %Creates parser for constructor function
        function createParser(this)
           p=inputParser;
           addParameter(p,'enable_gui',1);
           this.Parser=p;
        end
                
        %Sets the class variables to the inputs from the inputParser.
        function parseInputs(this)
            for i=1:length(this.Parser.Parameters)
                %Takes the value from the inputParser to the appropriate
                %property.
                if isprop(this,this.Parser.Parameters{i})
                    this.(this.Parser.Parameters{i})=...
                        this.Parser.Results.(this.Parser.Parameters{i});
                end
            end
        end
        
        %Initializes the class depending on the computer name
        function initDaq(this)
            computer_name=getenv('computername');
            switch computer_name
                case 'LPQM1PCLAB2'
                    initRt(this);
                case 'LPQM1PC18'
                    initUhq(this);
                case 'LPQM1PC2'
                    %Test case for testing on Nils' computer.
                otherwise
                    warning('Please create an initialization function for this computer')
            end
            
            %Initializes empty trace objects
            this.Ref=MyTrace;
            this.Data=MyTrace;
            this.Background=MyTrace;
        end

        %Sets callback functions for the GUI
        initGui(this)
        
        %Executes when the GUI is closed
        function closeFigure(this,~,~)
            delete(this);
        end
        
        %Adds an instrument to InstrList. Used by initialization functions.
        function addInstr(this,tag,name,type,interface,address)
            %Usage: addInstr(this,tag,name,type,interface,address)
            if ~ismember(tag,this.instr_tags)
                this.InstrList.(tag).name=name;
                this.InstrList.(tag).type=type;
                this.InstrList.(tag).interface=interface;
                this.InstrList.(tag).address=address;
            else
                error(['%s is already defined as an instrument. ',...
                    'Please choose a different tag'],tag);
            end
        end
        
        %Gets the tag corresponding to an instrument name
        function tag=getTag(this,instr_name)
            ind=cellfun(@(x) strcmp(this.InstrList.(x).name,instr_name),...
                this.instr_tags);
            tag=this.instr_tags{ind};
        end
        
        %Opens the correct instrument
        function openInstrument(this,tag)
            instr_type=this.InstrList.(tag).type;
            %Collects the correct inputs for creating the MyInstrument
            %class
            input_cell={this.InstrList.(tag).interface,...
                this.InstrList.(tag).address};
            
            switch instr_type
                case 'RSA'
                    this.Instruments.(tag)=MyRsa(input_cell{:},...
                        'gui','GuiRsa','name',this.InstrList.(tag).name);
                case 'Scope'
                    this.InstrApps.(tag)=GuiScope(input_cell{:},...
                        'name',this.InstrList.(tag).name);
                    this.Instruments.(tag)=this.InstrApps.(tag).Instr;
                case 'NA'
                    this.Instruments.(tag)=MyNa(input_cell{:},...
                        'gui','GuiNa','name',this.InstrList.(tag).name);
            end
            
            %Adds listeners for new data and deletion of the instrument.
            %These call plot functions and delete functions respectively.
            this.Listeners.(tag).NewData=...
                addlistener(this.Instruments.(tag),'NewData',...
                @(src, eventdata) acquireNewData(this, src, eventdata));
            this.Listeners.(tag).Deletion=...
                addlistener(this.Instruments.(tag),'ObjectBeingDestroyed',...
                @(src, eventdata) deleteInstrument(this, src, eventdata));
        end
        
        %Updates fits
        function updateFits(this)            
            %Pushes data into fits in the form of MyTrace objects, so that
            %units etc follow. Also updates user supplised parameters.
            for i=1:length(this.open_fits)
                switch this.open_fits{i}
                    case {'Linear','Quadratic','Gaussian',...
                            'Exponential','Beta'}
                        this.Fits.(this.open_fits{i}).Data=...
                            getFitData(this,'VertData');
                    case {'Lorentzian','DoubleLorentzian'}
                        this.Fits.(this.open_fits{i}).Data=...
                            getFitData(this,'VertData');
                        if isfield(this.Cursors,'VertRef')
                            ind=findCursorData(this,'Data','VertRef');
                            this.Fits.(this.open_fits{i}).CalVals.line_spacing=...
                                range(this.Data.x(ind));
                        end
                    case {'G0'}
                        this.Fits.G0.MechTrace=getFitData(this,'VertData');
                        this.Fits.G0.CalTrace=getFitData(this,'VertRef');
                end
            end
        end
        
        % If vertical cursors are on, takes only data
        %within cursors. 
        %If the cursor is not open, it takes all the data from the selected
        %trace in the analysis trace selection dropdown
        function Trace=getFitData(this,varargin)
            %Parses varargin input
            p=inputParser;
            addOptional(p,'name','',@ischar);
            parse(p,varargin{:})
            name=p.Results.name;
            
            %Finds out which trace the user wants to fit.
            trc_opts=this.Gui.SelTrace.String;
            trc_str=trc_opts{this.Gui.SelTrace.Value};
            % Note the use of copy here! This is a handle
            %class, so if normal assignment is used, this.Fits.Data and
            %this.(trace_str) will refer to the same object, causing roblems.
            %Name input is the name of the cursor to be used to extract data.
            Trace=copy(this.(trc_str));
            if isfield(this.Cursors,name)
                ind=findCursorData(this, trc_str, name);
                Trace.x=this.(trc_str).x(ind);
                Trace.y=this.(trc_str).y(ind);
            end
        end
        
        %Finds data between named cursors in the given trace
        function ind=findCursorData(this, trc_str, name)
            crs_pos=sort([this.Cursors.(name){1}.Location,...
                this.Cursors.(name){2}.Location]);
            ind=(this.(trc_str).x>crs_pos(1) & this.(trc_str).x<crs_pos(2));
        end
        
        %Creates either horizontal or vertical cursors
        function createCursors(this,name,type)
            %Checks that the cursors are of valid type
            assert(strcmp(type,'Horz') || strcmp(type,'Vert'),...
                'Cursorbars must be vertical or horizontal.');

            %Sets the correct color for the cursor
            switch name
                case 'HorzData'
                    color=[0,0,1];
                    crs_type='Horizontal';
                case 'VertData'
                    color=[1,0,0];
                    crs_type='Vertical';
                case 'VertRef'
                    color=[0.5,0,0.5];
                    crs_type='Vertical';
            end
            
            %Creates first cursor
            this.Cursors.(name){1}=cursorbar(this.main_plot,...
                'TargetMarkerStyle','none',...
                'ShowText','off','CursorLineWidth',0.5,...
                'Orientation',crs_type,'Tag',sprintf('%s1',name));
            %Creates second cursor
            this.Cursors.(name){2}=this.Cursors.(name){1}.duplicate;
            set(this.Cursors.(name){2},'Tag',sprintf('%s2',name))
            %Sets the cursor colors
            cellfun(@(x) setCursorColor(x, color),this.Cursors.(name));
            %Makes labels for the cursors
            labelCursors(this,name,type,color);
            addCursorListeners(this,name,type);
            cellfun(@(x) notify(x, 'UpdateCursorBar'), this.Cursors.(name));
        end
        
        %Labels cursors of a certain type and color
        function labelCursors(this, name, type, color)
            switch name
                case {'VertData', 'HorzData'}
                    lbl_str=name(1);
                case {'VertRef'}
                    lbl_str='R';
            end
            %Creates text boxes in a placeholder position
            this.CrsLabels.(name)=cellfun(@(x) text(0,0,...
                [lbl_str,x.Tag(end)]),this.Cursors.(name),...
                'UniformOutput',0);
            %Sets colors and properties on the labels.
            cellfun(@(x) set(x,'Color',color,'EdgeColor',color,...
                'FontWeight','bold','FontSize',10,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','middle'), this.CrsLabels.(name));
            positionCursorLabels(this, name, type);
        end
        
        %Resets the position of the labels 
        function positionCursorLabels(this, name, type)
            switch type
                case {'Horz','horizontal'}
                    %To set the offset off the side of the axes
                    xlim=get(this.main_plot,'XLim');
                    %Empirically determined nice point for labels
                    xloc=1.03*xlim(2)-0.03*xlim(1);
                    %Sets the position of the cursor labels
                    cellfun(@(x,y) set(x, 'Position',...
                        [xloc,y.Location,0]),...
                        this.CrsLabels.(name),this.Cursors.(name));
                    
                case {'Vert','vertical'}
                    %To set the offset off the top of the axes
                    ylim=get(this.main_plot,'YLim');
                    %Empirically determined nice point for labels
                    yloc=1.05*ylim(2)-0.05*ylim(1);
                    %Sets the position of the cursor labels
                    cellfun(@(x,y) set(x, 'Position',...
                        [y.Location,yloc,0]),...
                        this.CrsLabels.(name),this.Cursors.(name));
            end
            %Setting the position causes the line to update
            cellfun(@(x) set(x, 'Location', x.Location),...
                this.Cursors.(name));
        end
        
        %Adds listeners for cursors
        function addCursorListeners(this,name,type)
            switch type
                case {'Horz','horizontal'}
                    %Sets the update function of the cursor to move the
                    %text.
                    this.Listeners.(name).Update=cellfun(@(x) ...
                        addlistener(x,'UpdateCursorBar',...
                        @(src, ~) horzCursorUpdate(this, src)),...
                        this.Cursors.(name),'UniformOutput',0);
                case {'Vert','vertical'}
                    %Sets the update function of the cursors to move the
                    %text
                    this.Listeners.(name).Update=cellfun(@(x) ...
                        addlistener(x,'UpdateCursorBar',...
                        @(src, ~) vertCursorUpdate(this, src)),...
                        this.Cursors.(name),'UniformOutput',0);
                    %Sets the update function for end drag to update fits
                    this.Listeners.(name).EndDrag=cellfun(@(x) ...
                        addlistener(x,'EndDrag',...
                        @(~,~) updateFits(this)),this.Cursors.(name),...
                        'UniformOutput',0);
            end
        end
        
        %Updates the cursors to fill the axes
        function updateCursors(this)
            for i=1:length(this.open_crs)
                type=this.Cursors.(this.open_crs{i}){1}.Orientation;
                name=this.open_crs{i};
                switch type
                    case 'vertical'
                        cellfun(@(x) set(x.TopHandle, 'YData',...
                            this.main_plot.YLim(2)), this.Cursors.(name));
                        cellfun(@(x) set(x.BottomHandle, 'YData',...
                            this.main_plot.YLim(1)), this.Cursors.(name));
                    case 'horizontal'
                        cellfun(@(x) set(x.TopHandle, 'XData',...
                            this.main_plot.XLim(2)), this.Cursors.(name));
                        cellfun(@(x) set(x.BottomHandle, 'XData',...
                            this.main_plot.XLim(1)), this.Cursors.(name));
                end
                positionCursorLabels(this,name,type);
            end

        end
        
        %Deletes the cursors, their listeners and their labels.
        function deleteCursors(this, name)
            if contains(name,'Data')
                %Resets the edit boxes which contain cursor positions
                this.Gui.(sprintf('Edit%s1',name(1))).String='';
                this.Gui.(sprintf('Edit%s2',name(1))).String='';
                this.Gui.(sprintf('Edit%s2%s1',name(1),name(1))).String='';
            end
            %Deletes cursor listeners
            cellfun(@(x) deleteListeners(this,x.Tag), this.Cursors.(name));
            %Deletes the cursors themselves
            cellfun(@(x) delete(x), this.Cursors.(name));
            this.Cursors=rmfield(this.Cursors,name);
            %Deletes cursor labels
            cellfun(@(x) delete(x), this.CrsLabels.(name));
            this.CrsLabels=rmfield(this.CrsLabels,name);            
        end
        
        function copyPlot(this)
            %Conditions sizes
            posn=this.main_plot.OuterPosition;
            posn=posn.*[1,1,0.82,1.1];
            %Creates a new figure, this is to avoid copying all the buttons
            %etc to the clipboard.
            newFig = figure('visible','off','Units',this.main_plot.Units,...
                'Position',posn);
            %Copies the current axes into the new figure.
            newHandle = copyobj(this.main_plot,newFig); %#ok<NASGU>
            %Prints the figure to the clipboard
            print(newFig,'-clipboard','-dbitmap');
            %Deletes the figure
            delete(newFig);
        end
        
        function updateAxis(this)
            axis(this.main_plot,'tight');
        end
    end
    
    methods (Access=public)
        %% Callbacks
        
        %Callback for copying the plot to clipboard
        function copyPlotCallback(this,~,~)
            copyPlot(this);
        end
        
        %Callback for centering cursors
        function centerCursorsCallback(this, ~, ~)
            if ~this.Gui.LogX.Value
                x_pos=mean(this.main_plot.XLim);
            else
                x_pos=10^(mean(log10(this.main_plot.XLim)));
            end
            
            if ~this.Gui.LogY.Value
                y_pos=mean(this.main_plot.YLim);
            else
                y_pos=10^(mean(log10(this.main_plot.YLim)));
            end
                        
            for i=1:length(this.open_crs)
                switch this.Cursors.(this.open_crs{i}){1}.Orientation
                    case 'horizontal'
                        pos=y_pos;
                    case 'vertical'
                        pos=x_pos;
                end
                
                %Centers the position
                cellfun(@(x) set(x,'Location',pos), ...
                    this.Cursors.(this.open_crs{i}));
                %Triggers the UpdateCursorBar event, which triggers
                %listener callback to reposition text
                cellfun(@(x) notify(x,'UpdateCursorBar'),...
                    this.Cursors.(this.open_crs{i}));
                cellfun(@(x) notify(x,'EndDrag'),...
                    this.Cursors.(this.open_crs{i}));
            end
        end
        
        %Callback for creating vertical data cursors
        function cursorButtonCallback(this, hObject, ~)
            name=erase(hObject.Tag,'Button');
            %Gets the first four characters of the tag (Vert or Horz)
            type=name(1:4);
            
            if hObject.Value
                hObject.BackgroundColor=[0,1,0.2];
                createCursors(this,name,type);
            else
                hObject.BackgroundColor=[0.941,0.941,0.941];
                deleteCursors(this,name);
            end
        end
        
        %Callback for the instrument menu
        function instrMenuCallback(this,hObject,~)
            val=hObject.Value;
            %Finds the correct instrument tag as long as an instrument is
            %selected
            if val~=1
                names=hObject.String;
                tag=getTag(this,names(val));
            else 
                tag='';
            end
            %If instrument is valid and not open, opens it. If it is valid
            %and open it changes focus to the instrument control window.
            if ismember(tag,this.instr_tags) && ...
                    ~ismember(tag,this.open_instrs)
                openInstrument(this,tag);
            elseif ismember(tag,this.open_instrs)
                ind=structfun(@(x) isa(x,'matlab.ui.Figure'),...
                    this.Instruments.(tag).Gui);
                names=fieldnames(this.Instruments.(tag).Gui);
                figure(this.Instruments.(tag).Gui.(names{ind}));
            end
        end
        
        %Select trace callback
        function selTraceCallback(this, ~, ~)
            updateFits(this)
        end
        
        %Saves the data if the save data button is pressed.
        function saveDataCallback(this, ~, ~)
            if this.Data.validatePlot
                save(this.Data,'save_dir',this.save_dir,'name',...
                    this.savefile)
            else
                errdlg('Data trace was empty, could not save');
            end
        end
        
        %Saves the reference if the save ref button is pressed.
        function saveRefCallback(this, ~, ~)
            if this.Data.validatePlot
                save(this.Ref,'save_dir',this.save_dir,'name',...
                    this.savefile)
            else
                errdlg('Reference trace was empty, could not save')
            end
        end
        
        %Toggle button callback for showing the data trace.
        function showDataCallback(this, hObject, ~)
            if hObject.Value
                hObject.BackgroundColor=[0,1,0.2];
                setVisible(this.Data,this.main_plot,1);
                updateAxis(this);
            else
                hObject.BackgroundColor=[0.941,0.941,0.941];
                setVisible(this.Data,this.main_plot,0);
                updateAxis(this);
            end
        end
        
        %Toggle button callback for showing the ref trace
        function showRefCallback(this, hObject, ~)
            if hObject.Value
                hObject.BackgroundColor=[0,1,0.2];
                setVisible(this.Ref,this.main_plot,1);
                updateAxis(this);
            else
                hObject.BackgroundColor=[0.941,0.941,0.941];
                setVisible(this.Ref,this.main_plot,0);
                updateAxis(this);
            end
        end
        
        %Callback for moving the data to reference.
        function dataToRefCallback(this, ~, ~)
            if this.Data.validatePlot
                this.Ref.x=this.Data.x;
                this.Ref.y=this.Data.y;
                this.Ref.plotTrace(this.main_plot,'Color',this.ref_color,...
                    'make_labels',true);
                this.Ref.setVisible(this.main_plot,1);
                updateFits(this);
                this.Gui.ShowRef.Value=1;
                this.Gui.ShowRef.BackgroundColor=[0,1,0.2];
            else
                warning('Data trace was empty, could not move to reference')
            end
        end
        
        %Callback for ref to bg button. Sends the reference to background
        function refToBgCallback(this, ~, ~)
            if this.Ref.validatePlot
                this.Background.x=this.Ref.x;
                this.Background.y=this.Ref.y;
                this.Background.plotTrace(this.main_plot,...
                    'Color',this.bg_color,'make_labels',true);
                this.Background.setVisible(this.main_plot,1);
            else
                warning('Reference trace was empty, could not move to background')
            end
        end
        
        %Callback for data to bg button. Sends the data to background
        function dataToBgCallback(this, ~, ~)
            if this.Data.validatePlot
                this.Background.x=this.Data.x;
                this.Background.y=this.Data.y;
                this.Background.plotTrace(this.main_plot,...
                    'Color',this.bg_color,'make_labels',true);
                this.Background.setVisible(this.main_plot,1);
            else
                warning('Data trace was empty, could not move to background')
            end
        end
        
        %Callback for clear background button. Clears the background
        function clearBgCallback(this, ~, ~)
            this.Background.x=[];
            this.Background.y=[];
            this.Background.setVisible(this.main_plot,0);
        end
        
        %Callback for LogY button. Sets the YScale to log/lin
        function logYCallback(this, hObject, ~)
            if hObject.Value
                this.main_plot.YScale='Log';
                hObject.BackgroundColor=[0,1,0.2];
            else
                this.main_plot.YScale='Linear';
                hObject.BackgroundColor=[0.941,0.941,0.941];
            end
            updateAxis(this);
            updateCursors(this);
        end
        
        %Callback for LogX button. Sets the XScale to log/lin. Updates the
        %axis and cursors afterwards.
        function logXCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(this.main_plot,'XScale','Log');
                set(hObject, 'BackgroundColor',[0,1,0.2]);
            else
                set(this.main_plot,'XScale','Linear');
                set(hObject, 'BackgroundColor',[0.941,0.941,0.941]);
            end
            updateAxis(this);
            updateCursors(this);
        end
        
        %Base directory callback. Sets the base directory. Also
        %updates fit objects with the new save directory.
        function baseDirCallback(this, hObject, ~)
            this.base_dir=hObject.String;
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_dir=this.save_dir;
            end
        end
        
        %Callback for session name edit box. Sets the session name. Also
        %updates fit objects with the new save directory.
        function sessionNameCallback(this, hObject, ~)
            this.session_name=hObject.String;
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_dir=this.save_dir;
            end
        end
        
        %Callback for filename edit box. Sets the file name. Also
        %updates fit objects with the new file name.
        function fileNameCallback(this, hObject,~)
            this.file_name=hObject.String;
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_name=this.file_name;
            end
        end
       
        %Callback for the analyze menu (popup menu for selecting fits).
        %Opens the correct MyFit object.
        function analyzeMenuCallback(this, hObject, ~)
            analyze_ind=hObject.Value;
            %Finds the correct fit name by erasing spaces and other
            %superfluous strings
            analyze_name=hObject.String{analyze_ind};
            analyze_name=erase(analyze_name,'Fit');
            analyze_name=erase(analyze_name,'Calibration');
            analyze_name=erase(analyze_name,' ');
            
            switch analyze_name
                case {'Linear','Quadratic','Lorentzian','Gaussian',...
                        'DoubleLorentzian'}
                    openMyFit(this,analyze_name);
                case 'g0'
                    openMyG(this);
                case 'Beta'
                    openMyBeta(this);
            end
        end
        
        function openMyFit(this,fit_name)
            %Sees if the MyFit object is already open, if it is, changes the
            %focus to it, if not, opens it.
            if ismember(fit_name,fieldnames(this.Fits))
                %Changes focus to the relevant fit window
                figure(this.Fits.(fit_name).Gui.Window);
            else
                %Gets the data for the fit using the getFitData function
                %with the vertical cursors
                DataTrace=getFitData(this,'VertData');
                %Makes an instance of MyFit with correct parameters.
                this.Fits.(fit_name)=MyFit(...
                    'fit_name',fit_name,...
                    'enable_plot',1,...
                    'plot_handle',this.main_plot,...
                    'Data',DataTrace,...
                    'save_dir',this.save_dir,...
                    'save_name',this.file_name);
                
                updateFits(this);
                %Sets up a listener for the Deletion event, which
                %removes the MyFit object from the Fits structure if it is
                %deleted.
                this.Listeners.(fit_name).Deletion=...
                    addlistener(this.Fits.(fit_name),'ObjectBeingDestroyed',...
                    @(src, eventdata) deleteFit(this, src, eventdata));
                
                %Sets up a listener for the NewFit. Callback plots the fit
                %on the main plot.
                this.Listeners.(fit_name).NewFit=...
                    addlistener(this.Fits.(fit_name),'NewFit',...
                    @(src, eventdata) plotNewFit(this, src, eventdata));
                
                %Sets up a listener for NewInitVal
                this.Listeners.(fit_name).NewInitVal=...
                    addlistener(this.Fits.(fit_name),'NewInitVal',...
                    @(~,~) updateCursors(this));
            end
        end
        
        %Opens MyG class if it is not open.
        function openMyG(this)
            if ismember('G0',this.open_fits)
                figure(this.Fits.G0.Gui.figure1);
            else
                MechTrace=getFitData(this,'VertData');
                CalTrace=getFitData(this,'VertRef');
                this.Fits.G0=MyG('MechTrace',MechTrace,'CalTrace',CalTrace,...
                    'name','G0');
                
                %Adds listener for object being destroyed
                this.Listeners.G0.Deletion=addlistener(this.Fits.G0,...
                    'ObjectBeingDestroyed',...
                    @(~,~) deleteObj(this,'G0'));
            end
        end
        
        %Opens MyBeta class if it is not open.
        function openMyBeta(this)
            if ismember('Beta', this.open_fits)
                figure(this.Fits.Beta.Gui.figure1);
            else
                DataTrace=getFitData(this);
                this.Fits.Beta=MyBeta('Data',DataTrace);
                
                %Adds listener for object being destroyed, to perform cleanup
                this.Listeners.Beta.Deletion=addlistener(this.Fits.Beta,...
                    'ObjectBeingDestroyed',...
                    @(~,~) deleteObj(this,'Beta'));
            end
        end
        
        %Callback for load data button
        function loadDataCallback(this, ~, ~)
            if isempty(this.base_dir)
                warning('Please input a valid folder name for loading a trace');
                this.base_dir=pwd;
            end
            
            try
                [load_name,path_name]=uigetfile('.txt','Select the trace',...
                    this.base_dir);
                load_path=[path_name,load_name];
                dest_trc=this.Gui.DestTrc.String{this.Gui.DestTrc.Value};
                loadTrace(this.(dest_trc),load_path);
                this.(dest_trc).plotTrace(this.main_plot,...
                    'Color',this.(sprintf('%s_color',lower(dest_trc))),...
                    'make_labels',true);
                updateAxis(this);
                updateCursors(this);
            catch
                error('Please select a valid file');
            end            
        end
    end
    
    methods (Access=public)
        %% Listener functions 
        %Callback function for NewFit listener. Plots the fit in the
        %window using the plotFit function of the MyFit object
        function plotNewFit(this, src, ~)
            src.plotFit('Color',this.fit_color);
            updateAxis(this);
            updateCursors(this);
        end
        
        %Callback function for the NewData listener
        function acquireNewData(this, src, ~)
            hline=getLineHandle(this.Data,this.main_plot);
            this.Data=copy(src.Trace);
            if ~isempty(hline); this.Data.hlines{1}=hline; end
            clearData(src.Trace);
            this.Data.plotTrace(this.main_plot,'Color',this.data_color,...
                'make_labels',true)
            updateAxis(this);
            updateCursors(this);
            updateFits(this);
        end
        
        %Callback function for MyInstrument ObjectBeingDestroyed listener. 
        %Removes the relevant field from the Instruments struct and deletes
        %the listeners from the object
        function deleteInstrument(this, src, ~)
            %Deletes the object from the Instruments struct
            tag=getTag(this, src.name);
            if ismember(tag, this.open_instrs)
                this.Instruments=rmfield(this.Instruments,tag);
            end
            
            %Deletes the listeners from the Listeners struct
            deleteListeners(this, tag);
        end
        
        %Callback function for MyFit ObjectBeingDestroyed listener. 
        %Removes the relevant field from the Fits struct and deletes the 
        %listeners from the object.
        function deleteFit(this, src, ~)
            %Deletes the object from the Fits struct and deletes listeners 
            deleteObj(this,src.fit_name);
            
            %Clears the fits
            src.clearFit;
            
            %Updates cursors since the fits are removed from the plot
            updateCursors(this);
        end
        
        %Callback function for other analysis method deletion listeners.
        %Does the same as above.
        function deleteObj(this,name)
            if ismember(name,this.open_fits)
                this.Fits=rmfield(this.Fits,name);
            end
            deleteListeners(this, name);
        end
        
        %Listener update function for vertical cursor
        function vertCursorUpdate(this, src)
            %Finds the index of the cursor. All cursors are tagged
            %(name)1, (name)2, e.g. VertData2, ind is the number.
            ind=str2double(src.Tag(end));
            tag=src.Tag(1:(end-1));
            %Moves the cursor labels
            set(this.CrsLabels.(tag){ind},'Position',[src.Location,...
                this.CrsLabels.(tag){ind}.Position(2),0]);
            if strcmp(tag,'VertData')
                %Sets the edit box displaying the location of the cursor
                this.Gui.(sprintf('EditV%d',ind)).String=...
                    num2str(src.Location);
                %Sets the edit box displaying the difference in locations
                this.Gui.EditV2V1.String=...
                    num2str(this.Cursors.VertData{2}.Location-...
                    this.Cursors.VertData{1}.Location);
            end
        end
        
        %Listener update function for horizontal cursor
        function horzCursorUpdate(this, src)
            %Finds the index of the cursor. All cursors are tagged
            %(name)1, (name)2, e.g. VertData2, ind is the number.
            ind=str2double(src.Tag(end));
            tag=src.Tag(1:(end-1));
            %Moves the cursor labels
            set(this.CrsLabels.(tag){ind},'Position',...
                [this.CrsLabels.(tag){ind}.Position(1),...
                src.Location,0]);
            if strcmp(tag,'HorzData')
                %Sets the edit box displaying the location of the cursor
                this.Gui.(sprintf('EditH%d',ind)).String=...
                    num2str(src.Location);
                %Sets the edit box displaying the difference in locations
                this.Gui.EditH2H1.String=...
                    num2str(this.Cursors.HorzData{2}.Location-...
                    this.Cursors.HorzData{1}.Location);
            end
        end
               
        %Function that deletes listeners from the listeners struct,
        %corresponding to an object of name obj_name
        function deleteListeners(this, obj_name)
            %Finds if the object has listeners in the listeners structure
            if ismember(obj_name, fieldnames(this.Listeners))
                %Grabs the fieldnames of the object's listeners structure
                names=fieldnames(this.Listeners.(obj_name));
                for i=1:length(names)
                    %Deletes the listeners
                    delete(this.Listeners.(obj_name).(names{i}));
                    %Removes the field from the structure
                    this.Listeners.(obj_name)=...
                        rmfield(this.Listeners.(obj_name),names{i});
                end
                %Removes the object's field from the structure
                this.Listeners=rmfield(this.Listeners, obj_name);
            end
        end
    end
    
    methods
           
        %% Set functions
        function set.base_dir(this,base_dir)
            if ~strcmp(base_dir(end),'\')
                base_dir(end+1)='\';
            end
            this.base_dir=base_dir;
        end
        
        %% Get functions
        
        %Get function from save directory
        function save_dir=get.save_dir(this)
            save_dir=[this.base_dir,datestr(now,'yyyy-mm-dd '),...
                this.session_name,'\'];
        end
        
        %Get function for the plot handles
        function main_plot=get.main_plot(this)
            if this.enable_gui
                main_plot=this.Gui.figure1.CurrentAxes; 
            else
                main_plot=[];
            end
        end
        
        %Get function for available instrument tags
        function instr_tags=get.instr_tags(this)
            instr_tags=fieldnames(this.InstrList);
        end
        
        %Get function for open fits
        function open_fits=get.open_fits(this)
            open_fits=fieldnames(this.Fits);
        end
        
        %Get function for open instrument tags
        function open_instrs=get.open_instrs(this)
            open_instrs=fieldnames(this.Instruments);
        end
        
        %Get function for instrument names
        function instr_names=get.instr_names(this)
            %Cell of strings is output, so UniformOutput must be 0.
            instr_names=cellfun(@(x) this.InstrList.(x).name, ...
                this.instr_tags,'UniformOutput',0);
        end
        
        %Generates appropriate file name for the save file.
        function savefile=get.savefile(this)
            if get(this.Gui.AutoName,'Value')
                date_time = datestr(now,'yyyy-mm-dd_HHMMSS');
            else
                date_time='';
            end
            
            savefile=[this.file_name,date_time];
        end
        
        %Get function that displays names of open cursors
        function open_crs=get.open_crs(this)
            open_crs=fieldnames(this.Cursors);
        end
    end
end