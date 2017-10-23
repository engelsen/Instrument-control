classdef MyDaq < handle
    properties
        %Contains Gui handles
        Gui;
        %Contains Reference trace (MyTrace object)
        Ref;
        %Contains Data trace (MyTrace object)
        Data;
        %Contains Background trace (MyTrace object)
        Background;
        %Cell containing MyInstrument objects 
        Instruments;
        %Cell containing Cursor objects
        Cursors;
        %Struct containing MyFit objects
        Fits=struct();
        %Input parser
        Parser;
        %Listeners for deletion of MyFit objects
        ListenersDelete;
        %Listeners for new fits from MyFit objects
        ListenersNewFit;
        
        fit_color='k';
        data_color='b';
        ref_color='r';
        
        base_dir;
        session_name;
        file_name;
        enable_gui;
    end
    
    properties (Dependent=true)
        save_dir;
        main_plot;
    end
    
    methods
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
        
        function initDaq(this)
        computer_name=getenv('computername');

        switch computer_name
            case 'LPQM1PCLAB2'
                initRt(this);
            case 'LPQM1PC18'
                initUhq(this);
            otherwise
                %error('Please create an initialization function for this computer')
        end
        
        %Initializes empty trace objects
        this.Ref=MyTrace;
        this.Data=MyTrace;
        this.Background=MyTrace;
        end
        
        function initGui(this)
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
            set(this.Gui.AnalyzeMenu,'Callback',...
                @(hObject, eventdata) analyzeMenuCallback(this, hObject,...
                eventdata));
            set(this.Gui.AnalyzeMenu,'String',{'Select a routine...',...
                'Linear Fit','Quadratic Fit','Exponential Fit',...
                'Gaussian Fit','Lorentzian Fit'});
        end
        
        function saveDataCallback(this, ~, ~)   
            if get(this.Gui.AutoName,'Value')
                date_time = datestr(now,'yyyy-mm-dd_HH.MM.SS');
            else
                date_time='';
            end
            
            savefile=[this.file_name,date_time];
            save(this.Data,'save_dir',this.save_dir,'name',savefile)
        end
        
        function saveRefCallback(this, ~, ~)
            if get(this.Gui.AutoName,'Value')
                date_time = datestr(now,'yyyy-mm-dd_HH.MM.SS');
            else
                date_time='';
            end
            
            savefile=[this.file_name,date_time];
            save(this.Ref,'save_dir',this.save_dir,'name',savefile)
        end
        
        function baseDirCallback(this, hObject, ~)
            %Modify this at some point to use uiputfile instead
            this.base_dir=get(hObject,'String');
        end
        
        function showDataCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,.2]);
                setVisible(this.Data,this.main_plot,1);
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                setVisible(this.Data,this.main_plot,0);
            end
        end
        
        function showRefCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(hObject, 'BackGroundColor',[0,1,0.2]);
                setVisible(this.Ref,this.main_plot,1);
            else
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
                setVisible(this.Ref,this.main_plot,0);
            end
        end
        
        function dataToRefCallback(this, hObject, ~)
            set(hObject, 'BackGroundColor',[0,1,.2]);
            this.Ref.x=this.Data.x;
            this.Ref.y=this.Data.y;
            this.Ref.plotTrace(this.main_plot);
            this.Ref.setVisible(this.main_plot,1);
            set(this.Gui.ShowRef,'Value',1);
            set(this.Gui.ShowRef, 'BackGroundColor',[0,1,.2]);
            set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
        end
        
        function refToBgCallback(this, hObject, ~)
            set(hObject, 'BackGroundColor',[0,1,.2]);
            this.Background.x=this.Ref.x;
            this.Background.y=this.Ref.y;
            this.Background.plotTrace(this.main_plot);
            this.Background.setVisible(this.main_plot,1);
            set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
        end
        
        function dataToBgCallback(this, hObject, ~)
            set(hObject, 'BackGroundColor',[0,1,.2]);
            this.Background.x=this.Data.x;
            this.Background.y=this.Data.y;
            this.Background.plotTrace(this.main_plot);
            this.Background.setVisible(this.main_plot,1);
            set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
        end
        
        function clearBgCallback(this, hObject, ~)
            set(hObject, 'BackGroundColor',[0,1,.2]);
            this.Background.x=[];
            this.Background.y=[];
            this.Background.setVisible(this.main_plot,0);
            set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
        end
        
        function logYCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(this.main_plot,'YScale','Log');
                set(hObject, 'BackGroundColor',[0,1,.2]);
            else
                set(this.main_plot,'YScale','Linear');
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
            end
        end
        
        function logXCallback(this, hObject, ~)
            if get(hObject,'Value')
                set(this.main_plot,'XScale','Log');
                set(hObject, 'BackGroundColor',[0,1,.2]);
            else
                set(this.main_plot,'XScale','Linear');
                set(hObject, 'BackGroundColor',[0.941,0.941,0.941]);
            end
        end
        
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
                figure(this.Fits.(analyze_name).Gui.Window);
            elseif analyze_ind~=1
                this.Fits.(analyze_name)=MyFit('fit_name',analyze_name,...
                    'enable_plot',1,'plot_handle',this.main_plot);
                this.Fits.(analyze_name).Data=this.Data;
                this.ListenersDelete.(analyze_name)=...
                    addlistener(this.Fits.(analyze_name),'BeingDeleted',...
                    @(src, eventdata) deleteFit(this, src, eventdata));
                this.ListenersNewFit.(analyze_name)=...
                    addlistener(this.Fits.(analyze_name),'NewFit',...
                    @(src, eventdata) plotNewFit(this, src, eventdata));
            end
        end

        function sessionNameCallback(this, hObject, ~)
            this.session_name=get(hObject,'String');
        end
        
        function fileNameCallback(this, hObject,~)
            this.file_name=get(hObject,'String');
        end
       
        function save_dir=get.save_dir(this)
            save_dir=[this.base_dir,datestr(now,'yyyy-mm-dd '),...
                this.session_name,'\'];
        end
        
        function deleteFit(this, src, ~)
            if ismember(src.fit_name, fieldnames(this.Fits))
                this.Fits=rmfield(this.Fits,src.fit_name);
            end
        end
        
        function plotNewFit(this, src, ~)
            src.plotFit('Color',this.fit_color);
        end
        
        function main_plot=get.main_plot(this)
            if this.enable_gui
                main_plot=this.Gui.figure1.CurrentAxes; 
            else
                main_plot=[];
            end
        end
    end
end