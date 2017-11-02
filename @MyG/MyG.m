classdef MyG < handle
    properties
        %Trace of mechanical resonance
        MechTrace;
        %Trace of calibration tone
        CalTrace;
        %Struct containing Gui handles
        Gui;
        %Struct containing variable names corresponding to Gui edits
        VarStruct;
        %Contains inputParser
        Parser;
        temp;
        beta;
    end
    
    properties (Dependent=true)
        var_tags;
    end
    
    methods
        function this=MyG(varargin)
            createVarStruct(this);
            createParser(this);
            parse(this.Parser,varargin{:})
            this.Gui=guihandles(eval('GuiGCal'));
            
            this.MechTrace=this.Parser.Results.MechTrace;
            this.CalTrace=this.Parser.Results.CalTrace;
            
            this.beta=this.Parser.Results.beta;
            this.temp=this.Parser.Results.temp;
            
            initGui(this);
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
            set(this.Gui.CopyButton,'Callback',@(~,~) copyCallback(this));
            set(this.Gui.figure1, 'CloseRequestFcn',...
                @(~,~) closeFigure(this));
        end
        
        function calcG(this)
            %Conditions the caltrace by doing background subtraction, then
            %finds the area
            cal_bg=mean(this.CalTrace.y(1:5),this.CalTrace.y((end-4):end));
            this.CalTrace.y=this.CalTrace.y-cal_bg;
            cal_area=integrate(this.CalTrace);
            v_rms_eom=sqrt(cal_area);
            
            %Conditions the mechtrace by doing background subtraction, then
            %finds the area
            mech_bg=mean(this.MechTrace.y(1:5),this.MechTrace.y((end-4):end));
            this.MechTrace.y=this.MechTrace.y-mech_bg;
            mech_area=integrate(this.MechTrace);
            v_rms_mech=sqrt(mech_area);
            
            %Finds the mechanical frequency and the fwhm
            [~,mech_freq]=max(this.MechTrace);
            gamma_m=calcFwhm(this.MechTrace);
            q_m=mech_freq/gamma_m;
            
            %Defines constants and finds mechanical phononon number
            k_b=1.38e-23;
            h=6.63e-34;
            n_m=k_b*this.temp/(h*mech_freq);
            
            %Calculates g_0
            g0=(v_rms_mech/v_rms_eom)*this.beta*mech_freq/sqrt(4*n_m);
            
            set(this.Gui.MechFreq,'String',num2str(mech_freq/1e6,4));
            set(this.Gui.Q,'String',num2str(q_m,6));
            set(this.Gui.Linewidth,'String',num2str(gamma_m,5));
            set(this.Gui.g0,'String',num2str(g0,5));
        end
        
        %The close figure function calls the deletion method.
        function closeFigure(this)
            delete(this)
        end
        
        %Generic editbox callback which sets the appropriate property of
        %the class
        function editCallback(this, hObject)
            tag_str=erase(get(hObject,'Tag'),'Edit');
            var_str=this.VarStruct.(tag_str).var;
            this.(var_str)=str2double(get(hObject,'String'));
        end
        
        %Callback function for copying values to clipboard
        function copyCallback(this)
            mech_freq=get(this.Gui.MechFreq,'String');
            q_m=get(this.Gui.Q,'String');
            gamma_m=get(this.Gui.Linewidth,'String');
            g0=get(this.Gui.g0,'String');
            copy_string=sprintf('%s \t %s \t %s \t %s',...
                mech_freq,q_m,gamma_m,g0);
            clipboard('copy',copy_string);
        end
    end
    
    %% Set functions
    methods
        function set.beta(this,beta)
            this.beta=beta;
            set(this.Gui.BetaEdit,'String',num2str(this.beta));
        end
        
        function set.temp(this,temp)
            this.temp=temp;
            set(this.Gui.TempEdit,'String',num2str(this.temp));
        end
    end
    
    %% Get functions
    methods
        function var_tags=get.var_tags(this)
            var_tags=fieldnames(this.VarStruct);
        end
    end
end
