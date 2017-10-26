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
        Cursors;
        %Struct containing Cursor labels
        CrsLabels;
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
            set(this.Gui.BaseDir,'Callback',...
                @(hObject, eventdata) baseDirCallback(this, hObject, ...
                eventdata));
            set(this.Gui.SessionName,'Callback',...
                @(hObject, eventdata) sessionNameCallback(this, hObject, ...
                eventdata));
            set(this.Gui.FileName,'Callback',...
                @(hObject, eventdata) fileNameCallback(this, hObject, ...
                eventdata));
            set(this.Gui.SaveData,'Callback',...
                @(hObject, eventdata) saveDataCallback(this, hObject, ...
                eventdata));
            set(this.Gui.SaveRef,'Callback',...
                @(hObject, eventdata) saveRefCallback(this, hObject, ...
                eventdata));
            set(this.Gui.ShowData,'Callback',...
                @(hObject, eventdata) showDataCallback(this, hObject, ...
                eventdata));
            set(this.Gui.ShowRef,'Callback',...
                @(hObject, eventdata) showRefCallback(this, hObject, ...
                eventdata));
            set(this.Gui.DataToRef,'Callback',...
                @(hObject, eventdata) dataToRefCallback(this, hObject, ...
                eventdata));
            set(this.Gui.LogY,'Callback',...
                @(hObject, eventdata) logYCallback(this, hObject, ...
                eventdata));
            set(this.Gui.LogX,'Callback',...
                @(hObject, eventdata) logXCallback(this, hObject, ...
                eventdata));
            set(this.Gui.DataToBg,'Callback',...
                @(hObject, eventdata) dataToBgCallback(this, hObject, ...
                eventdata));
            set(this.Gui.RefToBg,'Callback',...
                @(hObject, eventdata) refToBgCallback(this, hObject, ...
                eventdata));
            set(this.Gui.ClearBg,'Callback',...
                @(hObject, eventdata) clearBgCallback(this, hObject, ...
                eventdata));
            set(this.Gui.SelTrace,'Callback',...
                @(hObject,eventdata) selTraceCallback(this, hObject, ...
                eventdata));
            set(this.Gui.VertCursor,'Callback',...
                @(hObject, eventdata) vertCursorCallback(this, hObject,...
                eventdata));
            set(this.Gui.HorzCursor,'Callback',...
                @(hObject, eventdata) horzCursorCallback(this, hObject,...
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
            input_cell={this.InstrList.(tag).name,...
                this.InstrList.(tag).interface,this.InstrList.(tag).address};
            
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
            
            %Adds listeners
            this.Listeners.(tag).NewData=...
                addlistener(this.Instruments.(tag),'NewData',...
                @(src, eventdata) acquireNewData(this, src, eventdata));
            this.Listeners.(tag).Deletion=...
                addlistener(this.Instruments.(tag),'ObjectBeingDestroyed',...
                @(src, eventdata) deleteInstrument(this, src, eventdata));
        end
        
        %Updates fits
        function updateFits(this)
            %Switch/case in case of more traces in the future
            switch get(this.Gui.SelTrace,'Value')
                case 1
                    for i=1:length(this.open_fits)
                        this.Fits.(this.open_fits{i}).Data=this.Data;
                    end
                case 2
                    for i=1:length(this.open_fits)
                        this.Fits.(this.open_fits{i}).Data=this.Ref;
                    end
            end
        end
        
        %Creates either horizontal or vertical cursors
        function createCursors(this,type)
            %Checks that the cursors are of valid type
            assert(strcmp(type,'Horizontal') || strcmp(type,'Vertical'),...
                'Cursorbars must be vertical or horizontal.');
            
            %Sets the correct color for the type of cursor
            switch type
                case 'Horizontal'
                    color=[0,0,1];
                case 'Vertical'
                    color=[1,0,0];
            end
            
            %Creates first cursor
            this.Cursors.(type){1}=cursorbar(this.main_plot,...
                'TargetMarkerStyle','none',...
                'ShowText','off','CursorLineWidth',0.5,...
                'Orientation',type,'Tag',sprintf('%s1',type(1)));
            %Creates second cursor
            this.Cursors.(type){2}=this.Cursors.(type){1}.duplicate;
            set(this.Cursors.(type){2},'Tag',sprintf('%s2',type(1)))
            %Sets the cursor colors
            setCursorColor(this,type,color)
            %Makes labels for the cursors
            labelCursors(this,type,color)
        end
        
        %Labels cursors of a certain type and color
        function labelCursors(this, type, color)
            %Creates text boxes in a placeholder position
            this.CrsLabels.(type)=cellfun(@(x) text(0,0,x.Tag),...
                this.Cursors.(type),'UniformOutput',0);
            %Sets colors and properties on the labels.
            cellfun(@(x) set(x,'Color',color,'EdgeColor',color,...
                'FontWeight','bold','FontSize',10,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','middle'), this.CrsLabels.(type));
            crs_loc=this.Cursors.(type){1}.location;
            switch type
                case 'Horizontal'
                    %To set the offset off the side of the axes
                    xlim=get(this.main_plot,'XLim');
                    %Sets the position of the cursor labels
                    cellfun(@(x) set(x, 'Position',[1.05*xlim(2),...
                        crs_loc,0]),this.CrsLabels.Horizontal);
                    %Sets the update function of the cursor to move the
                    %text.
                    this.Listeners.Horizontal=cellfun(@(x) ...
                        addlistener(x,'UpdateCursorBar',...
                        @(src, ~) horzCursorUpdate(this, src)),...
                        this.Cursors.Horizontal,'UniformOutput',0);
                case 'Vertical'
                    %To set the offset off the top of the axes
                    ylim=get(this.main_plot,'YLim');
                    %Sets the position of the cursor labels
                    cellfun(@(x) set(x, 'Position',...
                        [crs_loc,1.08*ylim(2),0]),this.CrsLabels.Vertical);
                    %Sets the update function of the cursors to move the
                    %text
                    this.Listeners.Vertical=cellfun(@(x) ...
                        addlistener(x,'UpdateCursorBar',...
                        @(src, ~) vertCursorUpdate(this, src)),...
                        this.Cursors.Vertical,'UniformOutput',0);
            end
        end
        
        %Update function for vertical cursor labels
        function vertCursorUpdate(this, src)
            ind=str2double(src.Tag(2));
            set(this.CrsLabels.Vertical{ind},'Position',[src.Location,...
                this.CrsLabels.Vertical{ind}.Position(2),0]);
        end
        
        %Update function for horizontal cursor labels
        function horzCursorUpdate(this, src)
            ind=str2double(src.Tag(2));
            set(this.CrsLabels.Horizontal{ind},'Position',...
                [this.CrsLabels.Horizontal{ind}.Position(1),...
                src.Location,0])
        end
        
        %Sets the color of the cursors of a certain type
        function setCursorColor(this, type, color)
            cellfun(@(x) set(x.TopHandle,'MarkerFaceColor',color),...
                this.Cursors.(type));
            cellfun(@(x) set(x.BottomHandle,'MarkerFaceColor',color),...
                this.Cursors.(type));
            cellfun(@(x) set(x,'CursorLineColor',color),...
                this.Cursors.(type));
        end
        
        %Deletes the cursors, their listeners and their labels.
        function deleteCursors(this, type)
            cellfun(@(x) deleteListeners(this,x.Tag), this.Cursors.(type));
            cellfun(@(x) delete(x), this.Cursors.(type));
            cellfun(@(x) delete(x), this.CrsLabels.(type));
        end
            
        %% Callbacks
        
        %Callback for creating vertical cursors
        function vertCursorCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,.2]);
                createCursors(this,'Vertical');
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                deleteCursors(this,'Vertical');
            end
        end
                
        %Callback for creating horizontal cursors
        function horzCursorCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,.2]);
                createCursors(this,'Horizontal');
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                deleteCursors(this,'Horizontal');
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
                
        %Base directory callback
        function baseDirCallback(this, hObject, ~)
            this.base_dir=get(hObject,'String');
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
                this.Ref.plotTrace(this.main_plot);
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
        
        %Callback for session name edit box. Sets the session name.
        function sessionNameCallback(this, hObject, ~)
            this.session_name=get(hObject,'String');
        end
        
        %Callback for filename edit box. Sets the file name.
        function fileNameCallback(this, hObject,~)
            this.file_name=get(hObject,'String');
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
                %Makes an instance of MyFit with correct parameters.
                this.Fits.(analyze_name)=MyFit('fit_name',analyze_name,...
                    'enable_plot',1,'plot_handle',this.main_plot);
                updateFits(this);
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
        end
        
        %Callback function for the NewData listener
        function acquireNewData(this, src, ~)
            this.Data=src.Trace;
            src.Trace.plotTrace(this.main_plot,'Color',this.data_color)
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
        end
        
        %Function that deletes listeners from the listeners struct,
        %corresponding to an object of name obj_name
        function deleteListeners(this, obj_name)
            if ismember(obj_name, fieldnames(this.Listeners))
                names=fieldnames(this.Listeners.(obj_name));
                for i=1:length(names)
                    delete(this.Listeners.(obj_name).(names{i}));
                    this.Listeners.(obj_name)=...
                        rmfield(this.Listeners.(obj_name),names{i});
                end
                this.Listeners=rmfield(this.Listeners, obj_name);
            end
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
                date_time = datestr(now,'yyyy-mm-dd_HH.MM.SS');
            else
                date_time='';
            end
            
            savefile=[this.file_name,date_time];
        end
        
    end
end