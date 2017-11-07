classdef MyG < handle
    properties (Access=public)
        %Name or tag of instance
        name
        %Trace of mechanical resonance
        MechTrace;
        %Trace of calibration tone
        CalTrace;
        
        temp;
        beta;
    end
    
    properties (GetAccess=public, SetAccess=private)
        %Struct containing Gui handles
        Gui;
        %Gui flag
        enable_gui;
        %Stores value of g0
        g0;
        gamma_m;
        mech_freq;
        q_m;
        k_b=1.38e-23;
        h=6.63e-34;
    end
    
    properties (Access=private)
        %Struct containing variable names corresponding to Gui edits
        VarStruct;
        %Contains inputParser
        Parser;
    end
    
    properties (Dependent=true)
        var_tags;
    end
    
    methods
        function this=MyG(varargin)
            createVarStruct(this);
            createParser(this);
            parse(this.Parser,varargin{:})
                       
            this.MechTrace=this.Parser.Results.MechTrace;
            this.CalTrace=this.Parser.Results.CalTrace;
            this.beta=this.Parser.Results.beta;
            this.temp=this.Parser.Results.temp;
            this.enable_gui=this.Parser.Results.enable_gui;
           
            if this.enable_gui
                 this.Gui=guihandles(eval('GuiGCal'));
                 initGui(this);
            end
        end
        
        %Class deletion function
        function delete(this)
            set(this.Gui.figure1,'CloseRequestFcn','');
            %Deletes the figure
            delete(this.Gui.figure1);
            %Removes the figure handle to prevent memory leaks
            this.Gui=[];
        end
        
        %Creates class input parser
        function createParser(this)
            p=inputParser;
            validateTrace=@(x) validateattributes(x,{'MyTrace'},...
                {'nonempty'});
            addParameter(p,'MechTrace',MyTrace(),validateTrace);
            addParameter(p,'CalTrace',MyTrace(),validateTrace);
            addParameter(p,'name','placeholder',@ischar);
            addParameter(p,'enable_gui',true);
            cellfun(@(x) addParameter(p, this.VarStruct.(x).var,...
                this.VarStruct.(x).default), this.var_tags);
            this.Parser=p;
        end
        
        %Creates the variable struct which contains variable names and
        %default values
        function createVarStruct(this)
            addVar(this,'Temp','temp',295);
            addVar(this,'Beta','beta',0);
        end
        
        %Adds a variable to the VarStruct
        function addVar(this,name,var,default)
            this.VarStruct.(name).var=var;
            this.VarStruct.(name).default=default;
        end
        
        %Initializes the GUI
        function initGui(this)
            cellfun(@(x) set(this.Gui.([x,'Edit']),'Callback',...
                @(hObject,~) editCallback(this,hObject)),...
                this.var_tags);
            this.Gui.CopyButton.Callback=@(~,~) copyCallback(this);
            this.Gui.figure1.CloseRequestFcn=@(~,~) closeFigure(this);
            this.Gui.AnalyzeButton.Callback=@(~,~) calcG(this);
        end
        
        function calcG(this)
            %Conditions the caltrace by doing background subtraction, then
            %finds the area
            cal_bg=mean([this.CalTrace.y(1:5);this.CalTrace.y((end-4):end)]);
            this.CalTrace.y=this.CalTrace.y-cal_bg;
            cal_area=integrate(this.CalTrace);
            v_rms_eom=sqrt(cal_area);
            
            %Conditions the mechtrace by doing background subtraction, then
            %finds the area
            mech_bg=mean([this.MechTrace.y(1:5);this.MechTrace.y((end-4):end)]);
            this.MechTrace.y=this.MechTrace.y-mech_bg;
            mech_area=integrate(this.MechTrace);
            v_rms_mech=sqrt(mech_area);
            
            %Finds the mechanical frequency and the fwhm
            [~,this.mech_freq]=max(this.MechTrace);
            this.gamma_m=calcFwhm(this.MechTrace);

            
            %Defines constants and finds mechanical phononon number

            n_m=this.k_b*this.temp/(this.h*this.mech_freq);
            
            %Calculates g_0
            this.g0=(v_rms_mech/v_rms_eom)*...
                this.beta*this.mech_freq/sqrt(4*n_m);
            
            if this.enable_gui
                set(this.Gui.MechFreq,'String',num2str(this.mech_freq/1e6,4));
                set(this.Gui.Q,'String',num2str(this.q_m,6));
                set(this.Gui.Linewidth,'String',num2str(this.gamma_m,5));
                set(this.Gui.g0,'String',num2str(this.g0,5));
            end
        end
        
        %The close figure function calls the deletion method.
        function closeFigure(this)
            delete(this);
        end
        
        %Generic editbox callback which sets the appropriate property of
        %the class
        function editCallback(this, hObject)
            tag_str=erase(get(hObject,'Tag'),'Edit');
            var_str=this.VarStruct.(tag_str).var;
            this.(var_str)=str2double(get(hObject,'String'));
            calcG(this);
        end
        
        %Callback function for copying values to clipboard
        function copyCallback(this)
            copy_string=sprintf('%s \t %s \t %s \t %s',...
                this.mech_freq,this.q_m,this.gamma_m,this.g0);
            clipboard('copy',copy_string);
        end
    end
    
    %% Set functions
    methods
        function set.beta(this,beta)
            this.beta=beta;
            if this.enable_gui 
                this.Gui.BetaEdit.String=num2str(this.beta); %#ok<MCSUP>
            end
        end
        
        function set.temp(this,temp)
            this.temp=temp;
            if this.enable_gui 
                this.Gui.TempEdit.String=num2str(this.temp); 
            end
            
        end
    end
    
    %% Get functions
    methods
        function var_tags=get.var_tags(this)
            var_tags=fieldnames(this.VarStruct);
        end
        
        function q_m=get.q_m(this)
            try
                q_m=this.mech_freq/this.gamma_m;
            catch
                q_m=NaN;
            end
        end
    end
end
