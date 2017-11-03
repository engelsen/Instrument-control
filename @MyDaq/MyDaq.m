classdef MyDaq < handle
    properties
        %Contains GUI handles
        Gui;
        %Contains Reference trace (MyTrace object)
        Ref;
        %Contains Data trace (MyTrace object)
        Data;
        %Contains Background trace (MyTrace object)
        Background;
        %Struct containing available instruments
        InstrList=struct();
        %Struct containing MyInstrument objects 
        Instruments=struct()
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
    
    methods
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
                set(this.Gui.figure1,'CloseRequestFcn','');
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
                    error('Please create an initialization function for this computer')
            end
            
            %Initializes empty trace objects
            this.Ref=MyTrace;
            this.Data=MyTrace;
            this.Background=MyTrace;
        end

        %Sets callback functions for the GUI
        function initGui(this)
            %Close request function is set to delete function of the class
            set(this.Gui.figure1, 'CloseRequestFcn',...
                @(hObject,eventdata) closeFigure(this, hObject, ...
                eventdata));
            %Sets callback for the edit box of the base directory
            set(this.Gui.BaseDir,'Callback',...
                @(hObject, eventdata) baseDirCallback(this, hObject, ...
                eventdata));
            %Sets callback for the session name edit box
            set(this.Gui.SessionName,'Callback',...
                @(hObject, eventdata) sessionNameCallback(this, hObject, ...
                eventdata));
            %Sets callback for the file name edit box
            set(this.Gui.FileName,'Callback',...
                @(hObject, eventdata) fileNameCallback(this, hObject, ...
                eventdata));
            %Sets callback for the save data button
            set(this.Gui.SaveData,'Callback',...
                @(hObject, eventdata) saveDataCallback(this, hObject, ...
                eventdata));
            %Sets callback for the save ref button
            set(this.Gui.SaveRef,'Callback',...
                @(hObject, eventdata) saveRefCallback(this, hObject, ...
                eventdata));
            %Sets callback for the show data button
            set(this.Gui.ShowData,'Callback',...
                @(hObject, eventdata) showDataCallback(this, hObject, ...
                eventdata));
            %Sets callback for the show reference button
            set(this.Gui.ShowRef,'Callback',...
                @(hObject, eventdata) showRefCallback(this, hObject, ...
                eventdata));
            %Sets callback for the data to reference button
            set(this.Gui.DataToRef,'Callback',...
                @(hObject, eventdata) dataToRefCallback(this, hObject, ...
                eventdata));
            %Sets callback for the LogY button
            set(this.Gui.LogY,'Callback',...
                @(hObject, eventdata) logYCallback(this, hObject, ...
                eventdata));
            %Sets callback for the LogX button
            set(this.Gui.LogX,'Callback',...
                @(hObject, eventdata) logXCallback(this, hObject, ...
                eventdata));
            %Sets callback for the data to background button
            set(this.Gui.DataToBg,'Callback',...
                @(hObject, eventdata) dataToBgCallback(this, hObject, ...
                eventdata));
            %Sets callback for the ref to background button
            set(this.Gui.RefToBg,'Callback',...
                @(hObject, eventdata) refToBgCallback(this, hObject, ...
                eventdata));
            %Sets callback for the clear background button
            set(this.Gui.ClearBg,'Callback',...
                @(hObject, eventdata) clearBgCallback(this, hObject, ...
                eventdata));
            %Sets callback for the select trace popup menu
            set(this.Gui.SelTrace,'Callback',...
                @(hObject,eventdata) selTraceCallback(this, hObject, ...
                eventdata));
            %Sets callback for the vertical cursor button
            set(this.Gui.VertCursor,'Callback',...
                @(hObject, eventdata) cursorButtonCallback(this, hObject,...
                eventdata));
            %Sets callback for the horizontal cursors button
            set(this.Gui.HorzCursor,'Callback',...
                @(hObject, eventdata) cursorButtonCallback(this, hObject,...
                eventdata));
            %Sets callback for the center cursors button
            set(this.Gui.CenterCursors,'Callback',...
                @(hObject,eventdata) centerCursorsCallback(this,hObject,...
                eventdata));
            %Sets callback for the center cursors button
            set(this.Gui.CopyPlot,'Callback',...
                @(hObject,eventdata) copyPlotCallback(this,hObject,...
                eventdata));
            
            %Initializes the AnalyzeMenu
            set(this.Gui.AnalyzeMenu,'Callback',...
                @(hObject, eventdata) analyzeMenuCallback(this, hObject,...
                eventdata));
            set(this.Gui.AnalyzeMenu,'String',{'Select a routine...',...
                'Linear Fit','Quadratic Fit','Exponential Fit',...
                'Gaussian Fit','Lorentzian Fit'});
            
            %Initializes the InstrMenu
            set(this.Gui.InstrMenu,'Callback',...
                @(hObject,eventdata) instrMenuCallback(this,hObject,...
                eventdata));
        end
        
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
            input_cell={this.InstrList.(tag).name,...
                this.InstrList.(tag).interface,...
                this.InstrList.(tag).address};
            
            switch instr_type
                case 'RSA'
                    this.Instruments.(tag)=MyRsa(input_cell{:},...
                        'gui','GuiRsa');
                case 'Scope'
                    this.Instruments.(tag)=MyScope(input_cell{:},...
                        'gui','GuiScope');
                case 'NA'
                    this.Instruments.(tag)=MyNa(input_cell{:},...
                        'gui','GuiNa');
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
            %units etc follow.
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).Data=getFitData(this,'Vert');
            end
        end
        
        % If vertical cursors are on, takes only data
        %within cursors. Note the use of copy here! This is a handle
        %class, so if normal assignment is used, this.Fits.Data and
        %this.(trace_str) will refer to the same object, causing roblems.
        function Trace=getFitData(this,name)
            %Finds out which trace the user wants to fit.
            trc_opts=get(this.Gui.SelTrace,'String');
            trc_str=trc_opts{get(this.Gui.SelTrace,'Value')};
            Trace=copy(this.(trc_str));
            if ismember(name,fieldnames(this.Cursors))
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
            %Creates text boxes in a placeholder position
            this.CrsLabels.(name)=cellfun(@(x) text(0,0,...
                [x.Tag(1),x.Tag(end)]),this.Cursors.(name),...
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
                set(this.Gui.(sprintf('Edit%s1',name(1))),'String','')
                set(this.Gui.(sprintf('Edit%s2',name(1))),'String','')
                set(this.Gui.(sprintf('Edit%s2%s1',name(1),name(1))),...
                    'String','');
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
    end
    
    methods
        %% Callbacks
        
        %Callback for copying the plot to clipboard
        function copyPlotCallback(this,~,~)
            copyPlot(this);
        end
        
        %Callback for centering cursors
        function centerCursorsCallback(this, ~, ~)
            x_pos=mean(get(this.main_plot,'XLim'));
            y_pos=mean(get(this.main_plot,'YLim'));
            
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
            tag=get(hObject,'Tag');
            %Gets the first four characters of the tag (Vert or Horz)
            type=tag(1:4);
            
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,.2]);
                createCursors(this,[type,'Data'],type);
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                deleteCursors(this,[type,'Data']);
            end
        end
        
        %Callback for the instrument menu
        function instrMenuCallback(this,hObject,~)
            val=get(hObject,'Value');
            if val~=1
                names=get(hObject,'String');
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
                figure(this.Instruments.(tag).figure1);
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
                error('Data trace was empty, could not save');
            end
        end
        
        %Saves the reference if the save ref button is pressed.
        function saveRefCallback(this, ~, ~)
            if this.Data.validatePlot
                save(this.Ref,'save_dir',this.save_dir,'name',...
                    this.savefile)
            else
                error('Reference trace was empty, could not save')
            end
        end
        
        %Toggle button callback for showing the data trace.
        function showDataCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,.2]);
                setVisible(this.Data,this.main_plot,1);
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                setVisible(this.Data,this.main_plot,0);
            end
        end
        
        %Toggle button callback for showing the ref trace
        function showRefCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,0.2]);
                setVisible(this.Ref,this.main_plot,1);
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                setVisible(this.Ref,this.main_plot,0);
            end
        end
        
        %Callback for moving the data to reference.
        function dataToRefCallback(this, ~, ~)
            if this.Data.validatePlot
                this.Ref.x=this.Data.x;
                this.Ref.y=this.Data.y;
                this.Ref.plotTrace(this.main_plot,'Color',this.ref_color);
                this.Ref.setVisible(this.main_plot,1);
                updateFits(this);
                set(this.Gui.ShowRef,'Value',1);
                set(this.Gui.ShowRef, 'BackGroundColor',[0,1,.2]);
            else
                warning('Data trace was empty, could not move to reference')
            end
        end
        
        %Callback for ref to bg button. Sends the reference to background
        function refToBgCallback(this, ~, ~)
            if this.Ref.validatePlot
                this.Background.x=this.Ref.x;
                this.Background.y=this.Ref.y;
                this.Background.plotTrace(this.main_plot);
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
                this.Background.plotTrace(this.main_plot);
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
            if get(hObject,'Value')
                set(this.main_plot,'YScale','Log');
                set(hObject, 'BackGroundColor',[0,1,.2]);
            else
                set(this.main_plot,'YScale','Linear');
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
            end
        end
        
        %Callback for LogX button. Sets the XScale to log/lin
        function logXCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(this.main_plot,'XScale','Log');
                set(hObject, 'BackGroundColor',[0,1,.2]);
            else
                set(this.main_plot,'XScale','Linear');
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
            end
        end
        
        %Base directory callback
        function baseDirCallback(this, hObject, ~)
            this.base_dir=get(hObject,'String');
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_dir=this.save_dir;
            end
        end
        
        %Callback for session name edit box. Sets the session name.
        function sessionNameCallback(this, hObject, ~)
            this.session_name=get(hObject,'String');
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_dir=this.save_dir;
            end
        end
        
        %Callback for filename edit box. Sets the file name.
        function fileNameCallback(this, hObject,~)
            this.file_name=get(hObject,'String');
            for i=1:length(this.open_fits)
                this.Fits.(this.open_fits{i}).save_name=this.file_name;
            end
        end
       
        %Callback for the analyze menu (popup menu for selecting fits).
        %Opens the correct MyFit object.
        function analyzeMenuCallback(this, hObject, ~)
            analyze_list=get(hObject,'String');
            analyze_ind=get(hObject,'Value');
            %Finds the correct fit name
            analyze_name=analyze_list{analyze_ind};
            analyze_name=analyze_name(1:(strfind(analyze_name,' ')-1));
            analyze_name=[upper(analyze_name(1)),analyze_name(2:end)];
            
            %Sees if the fit object is already open, if it is, changes the
            %focus to it, if not, opens it.
            if ismember(analyze_name,fieldnames(this.Fits))
                %Changes focus to the relevant fit window
                figure(this.Fits.(analyze_name).Gui.Window);
            elseif analyze_ind~=1
                DataTrace=getFitData(this,'Vert');
                %Makes an instance of MyFit with correct parameters.
                this.Fits.(analyze_name)=MyFit('fit_name',analyze_name,...
                    'enable_plot',1,'plot_handle',this.main_plot,...
                    'Data',DataTrace,'save_dir',this.save_dir,...
                    'save_name',this.file_name);

                %Sets up a listener for the Deletion event, which
                %removes the MyFit object from the Fits structure if it is
                %deleted.
                this.Listeners.(analyze_name).Deletion=...
                    addlistener(this.Fits.(analyze_name),'ObjectBeingDestroyed',...
                    @(src, eventdata) deleteFit(this, src, eventdata));
                
                %Sets up a listener for the NewFit. Callback plots the fit
                %on the main plot.
                this.Listeners.(analyze_name).NewFit=...
                    addlistener(this.Fits.(analyze_name),'NewFit',...
                    @(src, eventdata) plotNewFit(this, src, eventdata));
            end
        end
 
        %% Listener functions 
        %Callback function for NewFit listener. Plots the fit in the
        %window using the plotFit function of the MyFit object
        function plotNewFit(this, src, ~)
            src.plotFit('Color',this.fit_color);
            updateCursors(this);
        end
        
        %Callback function for the NewData listener
        function acquireNewData(this, src, ~)
            this.Data=src.Trace;
            src.Trace.plotTrace(this.main_plot,'Color',this.data_color)
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
            %Deletes the object from the Fits struct
            if ismember(src.fit_name, fieldnames(this.Fits))
                this.Fits=rmfield(this.Fits,src.fit_name);
            end
            
            %Deletes the listeners from the Listeners struct.
            deleteListeners(this, src.fit_name);
            
            %Updates cursors since the fits are removed from the plot
            updateCursors(this);
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
                set(this.Gui.(sprintf('EditV%d',ind)),'String',...
                    num2str(src.Location));
                %Sets the edit box displaying the difference in locations
                set(this.Gui.EditV2V1,'String',...
                    num2str(this.Cursors.VertData{2}.Location-...
                    this.Cursors.VertData{1}.Location))
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
                set(this.Gui.(sprintf('EditH%d',ind)),'String',...
                    num2str(src.Location));
                %Sets the edit box displaying the difference in locations
                set(this.Gui.EditH2H1,'String',...
                    num2str(this.Cursors.HorzData{2}.Location-...
                    this.Cursors.HorzData{1}.Location));
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