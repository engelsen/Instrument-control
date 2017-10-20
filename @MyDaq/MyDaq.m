classdef MyDaq < handle
    properties
        %Contains Gui handles
        Gui;
        %Contains Reference trace (MyTrace object)
        Reference;
        %Contains Data trace (MyTrace object)
        Data;
        %Contains Background trace (MyTrace object)
        Background;
        %Cell containing MyInstrument objects 
        Instruments;
        %Cell containing Cursor objects
        Cursors;
        %Cell containing MyFit objects
        Fits;
        %Input parser
        Parser;
        
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
                error('Please create an initialization function for this computer')
        end
        
        this.Reference=MyTrace;
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
        
        
        function main_plot=get.main_plot(this)
            main_plot=this.Gui.figure1.CurrentAxes;
        end
    end
end