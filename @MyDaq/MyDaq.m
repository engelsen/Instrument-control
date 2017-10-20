classdef MyDaq < handle
    properties
        Gui;
        Reference;
        Data;
        Background;
        Instruments;
        Cursors;
        Fits;
        Parser;
        save_dir;
        session_name;
        file_name;
        enable_gui;
    end
    
    properties (Dependent=true)
        save_path;
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
            set(this.Gui.SaveDir,'Callback',...
                @(hObject, eventdata) saveDirCallback(this, hObject, ...
                eventdata));
            set(this.Gui.SessionName,'Callback',...
                @(hObject, eventdata) sessionNameCallback(this, hObject, ...
                eventdata));
            set(this.Gui.FileName,'Callback',...
                @(hObject, eventdata) fileNameCallback(this, hObject, ...
                eventdata));
        end
        
        function saveDirCallback(this, hObject, ~)
            %Modify this at some point to use uiputfile instead
            this.save_dir=get(hObject,'String');
        end
        
        function sessionNameCallback(this, hObject, ~)
            this.session_name=get(hObject,'String');
        end
        
        function fileNameCallback(this, hObject,~)
            this.file_name=get(hObject,'String');
        end
        
        function set.save_dir(this, save_dir)
            this.save_dir=save_dir;
        end
        
        function save_path=get.save_path(this)
            save_path=[this.save_dir,this.session_name,'\',this.file_name,...
                '.txt'];
        end
        
        function main_plot=get.main_plot(this)
            main_plot=this.Gui.figure1.CurrentAxes;
        end
    end
end