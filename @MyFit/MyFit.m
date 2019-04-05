classdef MyFit < dynamicprops
    %Note that dynamicprops classes are handle classes.
    properties (Access=public)
        Data; %MyTrace object contains the data to be fitted to
        init_params=[]; %Contains the initial parameters
        lim_lower; %Lower limits for fit parameters
        lim_upper; %Upper limits for fit parameters
        enable_plot; %If enabled, plots initial parameters in the plot_handle
        plot_handle; %The handle which fits and init params are plotted in
        
        %Calibration values supplied externally
        CalVals=struct();
        
        init_color='c';
    end
    
    properties (GetAccess=public, SetAccess=private)
        Fit; %MyTrace object containing the fit
        Gui; %Gui handles
        %Output structures from fit:
        Fitdata;
        Gof;
        FitInfo;
        %Contains information about all the fits and their parameters
        FitStruct;
        coeffs;
        %The name of the fit used.
        fit_name='Linear'
    end
    
    properties (Access=private)
        %Structure used for initializing GUI of userpanel
        UserGui;
        Parser; %Input parser for constructor
        enable_gui=1;
        hline_init; %Handle for the plotted init values
        %Private struct used for saving file information when there is no
        %gui
        SaveInfo
        slider_vecs; %Vectors for varying the range of the sliders for different fits
    end
    
    %Dependent variables with no set methods
    properties (Dependent=true, SetAccess=private)
        %These grab and set the appropriate field of the FitStruct
        fit_function;
        anon_fit_fun;
        fit_tex;
        fit_params;
        fit_param_names;
        valid_fit_names;
        n_params;
        %These are used to create the usergui
        n_user_fields;
        user_field_tags;
        user_field_names;
        user_field_vals;
        %Vector used for plotting, depends on the data trace
        x_vec;
        %Variables used for saving
        fullpath;
        save_path;
        %Scaled x, y parameters for fitting
    end
    
    %Dependent variables with associated set methods
    properties (Dependent=true)
        filename;
        base_dir;
        session_name;
    end
    
    %Events for communicating with outside entities
    events
        NewFit;
        NewInitVal;
    end
    
    %Parser function
    methods (Access=private)
        %Creates parser for constructor
        function createParser(this)
            p=inputParser;
            addParameter(p,'fit_name','Linear',@ischar)
            addParameter(p,'Data',MyTrace());
            addParameter(p,'Fit',MyTrace());
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'enable_gui',1);
            addParameter(p,'enable_plot',0);
            addParameter(p,'plot_handle',[]);
            addParameter(p,'base_dir',this.SaveInfo.filename);
            addParameter(p,'session_name',this.SaveInfo.session_name);
            addParameter(p,'filename',this.SaveInfo.base_dir);
            this.Parser=p;
        end
    end
    %Public methods
    methods (Access=public)
        %Constructor function
        function this=MyFit(varargin)
            %Sets the default parameters for the save directory and
            %filename.
            this.SaveInfo.filename='placeholder';
            this.SaveInfo.session_name='placeholder';
            this.SaveInfo.base_dir=getLocalSettings('measurement_base_dir');
            
            %We first create the FitStruct, which contains all the
            %information about the available fits.
            createFitStruct(this);
            %We now create the parser for parsing the arguments to the
            %constructor, and parse the variables.
            createParser(this);
            parse(this.Parser,varargin{:});
            parseInputs(this);
            
            %Loads values into the CalVals struct depending on the type of
            %fit
            initCalVals(this);
            
            %Allows us to load either x/y data or a MyTrace object directly
            if ismember('Data',this.Parser.UsingDefaults) &&...
                    ~ismember('x',this.Parser.UsingDefaults) &&...
                    ~ismember('y',this.Parser.UsingDefaults)
                
                this.Data.x=this.Parser.Results.x;
                this.Data.y=this.Parser.Results.y;
            end
            
            %Sets dummy values for the GUI
            this.init_params=ones(1,this.n_params);
            this.lim_lower=-Inf(1,this.n_params);
            this.lim_upper=Inf(1,this.n_params);
            
            %Creates the structure that contains variables for calibration
            %of fit results
            createUserGuiStruct(this);
            
            %Creates the gui if the flag is enabled. This function is in a
            %separate file.
            if this.enable_gui
                createGui(this)
                %Generates the slider lookup table
                genSliderVecs(this);
            end
            
            %If the data is appropriate, generates initial
            %parameters 
            if validateData(this); genInitParams(this); end
        end
        
        %Deletion function of object
        function delete(this)
            if this.enable_gui
                %Avoids loops
                set(this.Gui.Window,'CloseRequestFcn','');
                %Deletes the figure
                delete(this.Gui.Window);
                %Removes the figure handle to prevent memory leaks
                this.Gui=[];
            end
            if ~isempty(this.hline_init); delete(this.hline_init); end
            if ~isempty(this.Fit.hlines); delete(this.Fit.hlines{:}); end
        end
        
        %Close figure callback simply calls delete function for class
        function closeFigure(this,~,~)
            delete(this);
        end
        
        %Saves the metadata
        function saveParams(this,varargin)
            p=inputParser;
            addParameter(p,'save_user_params',true);
            addParameter(p,'save_gof',true);
            parse(p,varargin{:});
            %Flags for saving the user parameters or goodness of fit
            save_user_params=p.Results.save_user_params;
            save_gof=p.Results.save_gof;
            
            assert(~isempty(this.coeffs) && ...
                length(this.coeffs)==this.n_params,...
                ['The number of calculated coefficients (%i) is not',...
                ' equal to the number of parameters (%i).', ...
                ' Perform a fit before trying to save parameters.'],...
                length(this.coeffs),this.n_params);
            
            %Creates combined strings of form: Linewidth (b), where
            %Linewidth is the parameter name and b is the parameter tag
            headers=cellfun(@(x,y) sprintf('%s (%s)',x,y),...
                this.fit_param_names, this.fit_params,'UniformOutput',0);
            save_data=this.coeffs;
            
            if save_user_params
                %Creates headers for the user fields
                user_field_headers=cellfun(@(x,y) ...
                    sprintf('%s. %s',this.UserGui.Fields.(x).parent,y),...
                    this.user_field_tags,this.user_field_names,...
                    'UniformOutput',0)';
                %Appends the user headers and data to the save data
                headers=[headers, user_field_headers];
                save_data=[save_data,this.user_field_vals'];
            end
            
            if save_gof
                %Appends GOF headers and data to the save data
                headers=[headers,fieldnames(this.Gof)'];
                save_data=[save_data,struct2array(this.Gof)];
            end
            
            %Find out at the end how many columns we have
            n_columns=length(headers);
            
            %Sets the column width. Pads 2 for legibility.
            col_width=cellfun(@(x) length(x), headers)+2;
            %Min column width of 24
            col_width(col_width<24)=24;
            
            %Create the right directories
            if ~exist(this.base_dir,'dir')
                mkdir(this.base_dir)
            end
            
            if ~exist(this.save_path,'dir')
                mkdir(this.save_path)
            end
            
            %We automatically append to the file if it already exists,
            %otherwise create a new file
            if exist(this.fullpath,'file')
                fileID=fopen(this.fullpath,'a');
                fprintf('Appending data to %s \n',this.fullpath);
            else
                fileID=fopen(this.fullpath,'w');
                pre_fmt_str=repmat('%%%is\\t',1,n_columns);
                fmt_str=sprintf([pre_fmt_str,'\r\n'],col_width);
                fprintf(fileID,fmt_str,headers{:});
            end
            
            pre_fmt_str_nmb=repmat('%%%i.15e\\t',1,n_columns);
            nmb_fmt_str=sprintf([pre_fmt_str_nmb,'\r\n'],col_width);
            fprintf(fileID,nmb_fmt_str,save_data);
            
            fclose(fileID);
        end
        
        %We can load a fit from a file with appropriately formatted columns
        %We simply load the coefficients from the file into the fit.
        function loadFit(this,fullfilename,varargin)
            p=inputParser;
            addParameter(p,'line_no',1);
            parse(p,varargin{:})
            n=p.Results.line_no;
            
            load_table=readtable(fullfilename);
            load_names=fieldnames(load_table);
            for i=1:this.n_params
                this.coeffs(i)=load_table.(load_names{i})(n);
            end
        end
        
        %This function is used to set the coefficients, to avoid setting it
        %to a number not equal to the number of parameters
        function setFitParams(this,coeffs)
            assert(length(coeffs)==this.n_params,...
                ['The length of the coefficient vector (currently %i) ',...
                'must be equal to the number of parameters (%i)'],...
                length(this.coeffs),this.n_params)
            this.coeffs=coeffs;
        end
        
        %Initializes the CalVals structure.
        function initCalVals(this)
            switch this.fit_name
                case 'Lorentzian'
                    %Line spacing is the spacing between all the lines,
                    %i.e. number of lines times the spacing between each
                    %one
                    this.CalVals.line_spacing=1;
                case 'DoubleLorentzian'
                    this.CalVals.line_spacing=1;
            end
        end
        
        %Fits the trace using currently set parameters, depending on the
        %model.
        function fitTrace(this)
            %Checks for valid data.
            assert(validateData(this),...
                ['The length of x is %d and the length of y is',...
                ' %d. The lengths must be equal and greater than ',...
                'the number of fit parameters to perform a fit'],...
                length(this.Data.x),length(this.Data.y))
            
            %Checks for valid limits.
            lim_check=this.lim_upper>this.lim_lower;
            assert(all(lim_check),...
                sprintf(['All upper limits must exceed lower limits. ',...
                'Check limit %i, fit parameter %s'],find(~lim_check,1),...
                this.fit_params{find(~lim_check,1)}));
            
            switch this.fit_name
                case 'Linear'
                    if this.Gui.ScaleButton.Value
                        s_c=...
                            polyfit(this.Data.scaled_x,this.Data.scaled_y,1);
                        this.coeffs=convScaledToRealCoeffs(this,s_c);
                    else
                        %Fits polynomial of order 1
                        this.coeffs=polyfit(this.Data.x,this.Data.y,1);
                    end
                case 'Quadratic'
                    %Fits polynomial of order 2
                    this.coeffs=polyfit(this.Data.x,this.Data.y,2);
                    this.Fit.y=polyval(this.coeffs,this.Fit.x);
                case {'Exponential','Lorentzian'}
                    if this.Gui.ScaleButton.Value
                        ft=fittype(this.fit_function,'coefficients',...
                            this.fit_params);
                        opts=fitoptions('Method','NonLinearLeastSquares',...
                            'Lower',convRealToScaledCoeffs(this,this.lim_lower),...
                            'Upper',convRealToScaledCoeffs(this,this.lim_upper),...
                            'StartPoint',convRealToScaledCoeffs(this,this.init_params),...
                            'MaxFunEvals',2000,...
                            'MaxIter',2000,...
                            'TolFun',1e-6,...
                            'TolX',1e-6);
                        %Fits with the below properties. Chosen for maximum accuracy.
                        [this.Fitdata,this.Gof,this.FitInfo]=...
                            fit(this.Data.scaled_x,this.Data.scaled_y,ft,opts);
                        %Puts the coeffs into the class variable.
                        this.coeffs=convScaledToRealCoeffs(this,...
                            coeffvalues(this.Fitdata));
                    else
                        doFit(this);
                    end
                case {'LorentzianGrad','Gaussian',...
                        'DoubleLorentzian','DoubleLorentzianGrad',...
                        'Gorodetsky2000','Gorodetsky2000plus'}
                    doFit(this)
                otherwise
                    error('Selected fit is invalid');
            end
            
            %This function calculates the fit trace, using this.x_vec as
            %the x axis
            calcFit(this);
            %This function calculates user-defined parameters
            calcUserParams(this);
            %Sets the new initial parameters to be the fitted parameters
            this.init_params=this.coeffs;
            %Updates the gui if it is enabled
            if this.enable_gui
                genSliderVecs(this);
                updateGui(this);
            end
            %Plots the fit if the flag is on
            if this.enable_plot; plotFit(this); end
            %Triggers new fit event
            triggerNewFit(this);
        end
        
        %This function calculates all the user-defined parameters shown in
        %the GUI. To add more parameters, add them in createUserGuiStruct,
        %then add them here when you wish to calculate them.
        function calcUserParams(this)
            switch this.fit_name
                case 'Lorentzian'
                    this.mech_lw=this.coeffs(2); %#ok<MCNPR>
                    this.mech_freq=this.coeffs(3); %#ok<MCNPR>
                    this.Q=this.mech_freq/this.mech_lw; %#ok<MCNPR>
                    this.opt_lw=convOptFreq(this,this.coeffs(2)); %#ok<MCNPR>
                    this.Qf=this.mech_freq*this.Q;  %#ok<MCNPR>
                case 'DoubleLorentzian'
                    this.opt_lw1=convOptFreq(this,this.coeffs(2)); %#ok<MCNPR>
                    this.opt_lw2=convOptFreq(this,this.coeffs(5)); %#ok<MCNPR>
                    splitting=abs(this.coeffs(6)-this.coeffs(3));
                    this.mode_split=convOptFreq(this,splitting); %#ok<MCNPR>
                case 'Exponential'
                    if ~isempty(this.coeffs)
                        this.tau=abs(1/this.coeffs(2)); %#ok<MCNPR>
                        this.lw=abs(this.coeffs(2)/pi); %#ok<MCNPR>
                    end
                    this.Q=pi*this.freq*this.tau; %#ok<MCNPR>
                    this.Qf=this.Q*this.freq; %#ok<MCNPR>
                otherwise
                    %If fit_name is not listed, do nothing
            end
            
        end
        
        %This function is used to convert the x-axis to frequency.
        function real_freq=convOptFreq(this,freq)
            real_freq=freq*this.spacing*this.line_no/this.CalVals.line_spacing;
        end
        
        %This struct is used to generate the UserGUI. Fields are seen under
        %tabs in the GUI. To create a new tab, you have to enter it under
        %this.UserGui.Tabs. A tab must have a tab_title and a field to add
        %Children. To add a field, use the addUserField function.
        function createUserGuiStruct(this)
            this.UserGui=struct('Fields',struct(),'Tabs',struct());
            switch this.fit_name
                case 'Lorentzian'
                    %Parameters for the tab relating to mechanics
                    this.UserGui.Tabs.Mech.tab_title='Mech.';
                    this.UserGui.Tabs.Mech.Children={};
                    addUserField(this,'Mech','mech_lw','Linewidth (Hz)',1,...
                        'enable_flag','off')
                    addUserField(this,'Mech','Q',...
                        'Qualify Factor (x10^6)',1e6,...
                        'enable_flag','off','conv_factor',1e6)
                    addUserField(this,'Mech','mech_freq','Frequency (MHz)',1e6,...
                        'conv_factor',1e6, 'enable_flag','off')
                    addUserField(this,'Mech','Qf','Q\times f (10^{14} Hz)',1e14,...
                        'conv_factor',1e14,'enable_flag','off');
                    
                    %Parameters for the tab relating to optics
                    this.UserGui.Tabs.Opt.tab_title='Optical';
                    this.UserGui.Tabs.Opt.Children={};
                    addUserField(this,'Opt','spacing',...
                        'Line Spacing (MHz)',1e6,'conv_factor',1e6,...
                        'Callback', @(~,~) calcUserParams(this));
                    addUserField(this,'Opt','line_no','Number of lines',10,...
                        'Callback', @(~,~) calcUserParams(this));
                    addUserField(this,'Opt','opt_lw','Linewidth (MHz)',1e6,...
                        'enable_flag','off','conv_factor',1e6);
                    
                case 'DoubleLorentzian'
                    this.UserGui.Tabs.Opt.tab_title='Optical';
                    this.UserGui.Tabs.Opt.Children={};
                    addUserField(this,'Opt','spacing',...
                        'Line Spacing (MHz)',1e6,'conv_factor',1e6,...
                        'Callback', @(~,~) calcUserParams(this));
                    addUserField(this,'Opt','line_no','Number of lines',10,...
                        'Callback', @(~,~) calcUserParams(this));
                    addUserField(this,'Opt','opt_lw1','Linewidth 1 (MHz)',1e6,...
                        'enable_flag','off','conv_factor',1e6);
                    addUserField(this,'Opt','opt_lw2','Linewidth 2 (MHz)',1e6,...
                        'enable_flag','off','conv_factor',1e6);
                    addUserField(this,'Opt','mode_split',...
                        'Modal splitting (MHz)',1e6,...
                        'enable_flag','off','conv_factor',1e6);
                case 'Exponential'
                    this.UserGui.Tabs.Q.tab_title='Q';
                    this.UserGui.Tabs.Q.Children={};
                    addUserField(this,'Q','tau','\tau (s)',1,...
                        'enable_flag','off')
                    addUserField(this,'Q','lw','Linewidth (Hz)',1,...
                        'enable_flag','off')
                    addUserField(this,'Q','Q',...
                        'Qualify Factor (x10^6)',1e6,...
                        'enable_flag','off','conv_factor',1e6)
                    addUserField(this,'Q','freq','Frequency (MHz)',1e6,...
                        'conv_factor',1e6, 'enable_flag','on',...
                        'Callback',@(~,~) calcUserParams(this));
                    addUserField(this,'Q','Qf','Q\times f (10^{14} Hz)',1e14,...
                        'conv_factor',1e14,'enable_flag','off');
                    addUserField(this,'Q','tag','Tag (number)','',...
                        'enable_flag','on')
                otherwise
                    %Do nothing if there is no defined user parameters
            end
        end
        
        %Parent is the parent tab for the userfield, tag is the tag given
        %to the GUI element, title is the text written next to the field,
        %initial value is the initial value of the property and change_flag
        %determines whether the gui element is enabled for writing or not.
        %conv_factor is used to have different units in the field. In the
        %program, the value is always saved as the bare value.
        function addUserField(this, parent, tag, title, ...
                init_val,varargin)
            %Parsing inputs
            p=inputParser();
            addRequired(p,'Parent');
            addRequired(p,'Tag');
            addRequired(p,'Title');
            addRequired(p,'init_val');
            addParameter(p,'enable_flag','on');
            addParameter(p,'Callback','');
            addParameter(p,'conv_factor',1);
            
            parse(p,parent,tag,title,init_val,varargin{:});
            tag=p.Results.Tag;
            
            %Populates the UserGui struct
            this.UserGui.Fields.(tag).parent=p.Results.Parent;
            this.UserGui.Fields.(tag).title=p.Results.Title;
            this.UserGui.Fields.(tag).init_val=p.Results.init_val;
            this.UserGui.Fields.(tag).enable_flag=...
                p.Results.enable_flag;
            this.UserGui.Fields.(tag).conv_factor=p.Results.conv_factor;
            this.UserGui.Fields.(tag).Callback=...
                p.Results.Callback;
            
            this.UserGui.Tabs.(p.Results.Parent).Children{end+1}=tag;
            %Adds the new property to the class
            addUserProp(this, tag);
            
        end
        
        %Every user field has an associated property, which is added by
        %this function. The get and set functions are set to use the GUI
        %through the getUserVal and setUserVal functions if the GUI is
        %enabled.
        function addUserProp(this,tag)
            prop=addprop(this,tag);
            if this.enable_gui
                prop.GetMethod=@(this) getUserVal(this,tag);
                prop.SetMethod=@(this, val) setUserVal(this, val, tag);
                prop.Dependent=true;
            end
        end
        
        %This function gets the value of the userprop from the GUI. The GUI
        %is the single point of truth
        function val=getUserVal(this, tag)
            conv_factor=this.UserGui.Fields.(tag).conv_factor;
            val=str2double(this.Gui.([tag,'Edit']).String)*conv_factor;
        end
        
        %As above, but instead we set the GUI through setting the property
        function setUserVal(this, val, tag)
            conv_factor=this.UserGui.Fields.(tag).conv_factor;
            this.Gui.([tag,'Edit']).String=num2str(val/conv_factor);
        end
        %Generates model-dependent initial parameters, lower and upper
        %boundaries.
        function genInitParams(this)
            assert(validateData(this), ['The data must be vectors of',...
                ' equal length greater than the number of fit parameters.',...
                ' Currently the number of fit parameters is %d, the',...
                ' length of x is %d and the length of y is %d'],...
                this.n_params,length(this.Data.x),length(this.Data.y));
            %Cell for putting parameters in to be interpreted in the
            %parser. Element 1 contains the init params, Element 2 contains
            %the lower limits and Element 3 contains the upper limits.
            params={};
            
            switch this.fit_name
                case 'Exponential'
                    [params{1},params{2},params{3}]=...
                        initParamExponential(this.Data.x,this.Data.y);
                case 'Gaussian'
                    [params{1},params{2},params{3}]=...
                        initParamGaussian(this.Data.x,this.Data.y);
                case 'Lorentzian'
                    [params{1},params{2},params{3}]=...
                        initParamLorentzian(this.Data.x,this.Data.y);
                case 'LorentzianGrad'
                    [params{1},params{2},params{3}]=...
                        initParamLorentzianGrad(this.Data.x,this.Data.y);
                case 'DoubleLorentzian'
                    [params{1},params{2},params{3}]=...
                        initParamDblLorentzian(this.Data.x,this.Data.y);
                case 'DoubleLorentzianGrad'
                    [params{1},params{2},params{3}]=...
                        initParamDblLorentzianGrad(this.Data.x,this.Data.y);
                case 'Gorodetsky2000'
                    [params{1},params{2},params{3}]=...
                        initParamGorodetsky2000(this.Data.x,this.Data.y);
                case 'Gorodetsky2000plus'
                    [params{1},params{2},params{3}]=...
                        initParamGorodetsky2000Plus(this.Data.x,this.Data.y);
            end
            
            %Validates the initial parameters
            p=createFitParser(this.n_params);
            parse(p,params{:});
            
            %Loads the parsed results into the class variables
            this.init_params=p.Results.init_params;
            this.lim_lower=p.Results.lower;
            this.lim_upper=p.Results.upper;
            
            %Plots the fit function with the new initial parameters
            if this.enable_plot; plotInitFun(this); end
            %Updates the GUI and creates new lookup tables for the init
            %param sliders
            if this.enable_gui
                genSliderVecs(this);
                updateGui(this);                 
            end
        end
        
        %Calculates the trace object for the fit
        function calcFit(this)
            this.Fit.x=this.x_vec;
            input_coeffs=num2cell(this.coeffs);
            this.Fit.y=this.anon_fit_fun(this.Fit.x,input_coeffs{:});
        end
        %Plots the trace contained in the Fit MyTrace object after
        %calculating the new values
        function plotFit(this,varargin)
            calcFit(this);
            assert((isa(this.plot_handle,'matlab.graphics.axis.Axes')||...
                isa(this.plot_handle,'matlab.ui.control.UIAxes')),...
                'plot_handle property must be defined to valid axis in order to plot')
            this.Fit.plot(this.plot_handle,varargin{:});
            clearInitFun(this);
        end
        
        %Clears the plots
        function clearFit(this)
            cellfun(@(x) delete(x), this.Fit.hlines);
            clearInitFun(this);
            this.Fit.hlines={};
        end
        
        function clearInitFun(this)
            delete(this.hline_init);
            this.hline_init=[];
        end
        
        %Function for plotting fit model with current initial parameters.
        function plotInitFun(this)
            %Substantially faster than any alternative - generating
            %anonymous functions is very cpu intensive.
            
            input_cell=num2cell(this.init_params);
            y_vec=feval(this.FitStruct.(this.fit_name).anon_fit_fun,...
                this.x_vec,input_cell{:});
            if isempty(this.hline_init)
                this.hline_init=plot(this.plot_handle,this.x_vec,y_vec,...
                    'Color',this.init_color);
            else
                set(this.hline_init,'XData',this.x_vec,'YData',y_vec);
            end
        end
    end
    
    %Callbacks
    methods
        %Save fit function callback
        function saveFitCallback(this,~,~)
            assert(~isempty(this.base_dir),'Save directory is not specified');
            assert(ischar(this.base_dir),...
                ['Save directory is not specified.',...
                ' Should be of type char but is %s.'], ...
                class(this.base_dir))
            this.Fit.save('name',this.filename,...
                'base_dir',this.save_path)
        end
        
        %Callback for saving parameters
        function saveParamCallback(this,~,~)
            saveParams(this);
        end
        
        function genSliderVecs(this)
            %Return values of the slider
            slider_vals=1:101;
            %Default scaling vector
            def_vec=10.^((slider_vals-51)/50);
            %Sets the cell to the default value
            for i=1:this.n_params
                this.slider_vecs{i}=def_vec*this.init_params(i);
                set(this.Gui.(sprintf('Slider_%s',this.fit_params{i})),...
                    'Value',50);
            end
            
            %Here we can put special cases such that the sliders can behave
            %differently for different fits. 
            if validateData(this)
                switch this.fit_name
                    case 'Lorentzian'
                        %We choose to have the slider go over the range of
                        %the x-values of the plot for the center of the
                        %Lorentzian.
                        this.slider_vecs{3}=...
                            linspace(this.x_vec(1),this.x_vec(end),101);
                        %Find the index closest to the init parameter
                        [~,ind]=...
                            min(abs(this.init_params(3)-this.slider_vecs{3}));
                        %Set to ind-1 as the slider goes from 0 to 100
                        set(this.Gui.(sprintf('Slider_%s',...
                            this.fit_params{3})),'Value',ind-1);
                end
            end
        end
        
        %Callback functions for sliders in GUI. Uses param_ind to find out
        %which slider the call is coming from, this was implemented to
        %speed up the callback. Note that this gets triggered whenever the
        %value of the slider is changed.
        function sliderCallback(this, param_ind, hObject, ~)
            %Gets the value from the slider
            val=get(hObject,'Value');
            
            %Find out if the current slider value is correct for the
            %current init param value. If so, do not change anything. This
            %is required as the callback also gets called when the slider
            %values are changed programmatically
            [~,ind]=...
                min(abs(this.init_params(param_ind)-this.slider_vecs{param_ind}));           
            if ind~=(val+1)
                %Updates the scale with a new value from the lookup table
                this.init_params(param_ind)=...
                    this.slider_vecs{param_ind}(val+1);
                %Updates the edit box with the new value from the slider
                set(this.Gui.(sprintf('Edit_%s',this.fit_params{param_ind})),...
                    'String',sprintf('%3.3e',this.init_params(param_ind)));
                if this.enable_plot; plotInitFun(this); end
            end
        end
        
         %Callback function for edit boxes in GUI
        function editCallback(this, hObject, ~)
            init_param=str2double(hObject.String);
            param_ind=str2double(hObject.Tag);

            %Centers the slider 
            set(this.Gui.(sprintf('Slider_%s',this.fit_params{param_ind})),...
                'Value',50);
            %Updates the correct initial parameter
            this.init_params(param_ind)=init_param;
            if this.enable_plot; plotInitFun(this); end
            %Triggers event for new init values
            triggerNewInitVal(this);
            %Generate the new slider vectors
            genSliderVecs(this);
        end
        
        %Callback function for editing limits in the GUI
        function limEditCallback(this, hObject,~)
            lim = str2double(hObject.String);
            %Regexp finds type (lower or upper bound) and index
            expr = '(?<type>Upper|Lower)(?<ind>\d+)';
            s=regexp(hObject.Tag,expr,'names');
            ind=str2double(s.ind);
            
            switch s.type
                case 'Lower'
                    this.lim_lower(ind)=lim;
                case 'Upper'
                    this.lim_upper(ind)=lim;
                otherwise
                    error('%s is not properly named for assignment of limits',...
                        hObject.Tag);
            end
        end
        
        %Callback function for analyze button in GUI. Checks if the data is
        %ready for fitting.
        function analyzeCallback(this, ~, ~)
            fitTrace(this);
        end
        
        %Callback for clearing the fits on the axis.
        function clearFitCallback(this,~,~)
            clearFit(this);
        end
        
        %Callback function for generate init parameters button. 
        function initParamCallback(this,~,~)
            genInitParams(this);
        end
        
        %Callback function for scaleData button
        function scaleDataCallback(~,hObject)
            if hObject.Value
                hObject.BackgroundColor=0.9*[1,1,1];
            else
                hObject.BackgroundColor=[1,1,1];
            end
        end
    end
    
    %Private methods
    methods(Access=private)
        %Creates the GUI of MyFit, in separate file.
        createGui(this);
        
        %Creates a panel for the GUI, in separate file
        createTab(this, tab_tag, bg_color, button_h);
        
        %Creats two vboxes (from GUI layouts) to display values of
        %quantities
        createUnitBox(this, bg_color, h_parent, name);
        
        %Creates an edit box inside a UnitDisp for showing label and value of
        %a quantity. Used in conjunction with createUnitBox
        createUnitDisp(this,varargin);
                
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
        
        %Does the fit with the currently set parameters
        function doFit(this)
            ft=fittype(this.fit_function,'coefficients',this.fit_params);
            opts=fitoptions('Method','NonLinearLeastSquares',...
                'Lower',this.lim_lower,...
                'Upper',this.lim_upper,...
                'StartPoint',this.init_params,...
                'MaxFunEvals',2000,...
                'MaxIter',2000,...
                'TolFun',1e-6,...
                'TolX',1e-6);
            %Fits with the below properties. Chosen for maximum accuracy.
            [this.Fitdata,this.Gof,this.FitInfo]=...
                fit(this.Data.x,this.Data.y,ft,opts);
            %Puts the coeffs into the class variable.
            this.coeffs=coeffvalues(this.Fitdata);
        end
        
        %Converts scaled coefficients to real coefficients
        function r_c=convScaledToRealCoeffs(this,s_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            switch this.fit_name
                case 'Linear'
                    r_c(1)=std_y/std_x*s_c(1);
                    r_c(2)=(s_c(2)-s_c(1)*mean_x/std_x)*std_y+mean_y;
                case 'Exponential'
                    r_c(1)=exp(-s_c(2)*mean_x/std_x)*s_c(1)*std_y;
                    r_c(2)=s_c(2)/std_x;
                    r_c(3)=std_y*s_c(3)+mean_y;
                case 'Lorentzian'
                    r_c(1)=s_c(1)*std_y*std_x;
                    r_c(2)=s_c(2)*std_x;
                    r_c(3)=s_c(3)*std_x+mean_x;
                    r_c(4)=s_c(4)*std_y+mean_y;
            end
        end
        
        function s_c=convRealToScaledCoeffs(this,r_c)
            [mean_x,std_x,mean_y,std_y]=calcZScore(this.Data);
            
            switch this.fit_name
                case 'Linear'
                    s_c(1)=std_x/std_y*r_c(1);
                    s_c(2)=(r_c(2)-mean_y)/std_y+s_c(1)*mean_x/std_x;
                case 'Exponential'
                    s_c(2)=r_c(2)*std_x;
                    s_c(1)=r_c(1)*exp(s_c(2)*mean_x/std_x)/std_y;
                    s_c(3)=(r_c(3)-mean_y)/std_y;
                case 'Lorentzian'
                    s_c(1)=r_c(1)/(std_y*std_x);
                    s_c(2)=r_c(2)/std_x;
                    s_c(3)=(r_c(3)-mean_x)/std_x;
                    s_c(4)=(r_c(4)-mean_y)/std_y;
            end
        end
        %Triggers the NewFit event such that other objects can use this to
        %e.g. plot new fits
        function triggerNewFit(this)
            notify(this,'NewFit');
        end
        
        %Triggers the NewInitVal event
        function triggerNewInitVal(this)
            notify(this,'NewInitVal');
        end
        
        %Creates the struct used to get all things relevant to the fit
        %model. Ensure that fit parameters are listed alphabetically, as
        %otherwise the anon_fit_fun will not work properly.
        function createFitStruct(this)
            %Adds fits
            addFit(this,'Linear','a*x+b','$$ax+b$$',{'a','b'},...
                {'Gradient','Offset'})
            addFit(this,'Quadratic','a*x^2+b*x+c','$$ax^2+bx+c$$',...
                {'a','b','c'},{'Quadratic coeff.','Linear coeff.','Offset'});
            addFit(this,'Gaussian','a*exp(-((x-c)/b)^2/2)+d',...
                '$$ae^{-\frac{(x-c)^2}{2b^2}}+d$$',{'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'Lorentzian','1/pi*a*b/2/((x-c)^2+(b/2)^2)+d',...
                '$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d$$',...
                {'a','b','c','d'},...
                {'Amplitude','Width','Center','Offset'});
            addFit(this,'LorentzianGrad','1/pi*a*b/2/((x-c)^2+(b/2)^2)+d*(x-c)+e',...
                '$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+d*(x-b)+e$$',...
                {'a','b','c','d','e'},...
                {'Amplitude','Width','Center','Gradient','Offset'});
            addFit(this,'Exponential','a*exp(b*x)+c',...
                '$$ae^{bx}+c$$',{'a','b','c'},...
                {'Amplitude','Rate','Offset'});
            addFit(this,'DoubleLorentzian',...
                '1/pi*b/2*a/((x-c)^2+(b/2)^2)+1/pi*e/2*d/((x-f)^2+(e/2)^2)+g',...
                '$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+\frac{d}{\pi}\frac{e/2}{(x-f)^2+(e/2)^2}+g$$',...
                {'a','b','c','d','e','f','g'},...
                {'Amplitude 1','Width 1','Center 1','Amplitude 2',...
                'Width 2','Center 2','Offset'});
            addFit(this,'DoubleLorentzianGrad',...
                '1/pi*b/2*a/((x-c)^2+(b/2)^2)+1/pi*e/2*d/((x-f)^2+(e/2)^2)+g*(x-c)+h',...
                '$$\frac{a}{\pi}\frac{b/2}{(x-c)^2+(b/2)^2}+\frac{d}{\pi}\frac{e/2}{(x-f)^2+(e/2)^2}+g*x+h$$',...
                {'a','b','c','d','e','f','g','h'},...
                {'Amplitude 1','Width 1','Center 1','Amplitude 2',...
                'Width 2','Center 2','Gradient','Offset'});
             addFit(this,'Gorodetsky2000',...
                ['a*abs( (k0^2/4 - kex^2/4 + gamma^2/4 - (x-b).^2 + i*k0.*(x-b))',...
                './( (k0 + kex)^2/4 + gamma^2/4 - (x-b).^2 + i.*(x-b)*(k0 + kex) )).^2+c*(x-b)'],...
                ['$$a\left|\frac{\kappa_0^2/4-\kappa_{ex}^2/4+\gamma^2/4-(x-b)^2+i\kappa_0(x-b)/2}',...
                '{(\kappa_0+\kappa_{ex})^2/4+\gamma^2/4-(x-b)^2+i(x-b)(\kappa_0+\kappa_{ex})}\right|^2$$+c(x-b)'],...
                { 'a','b','c','gamma','k0', 'kex'},...
                {'Background','Center','BG Slope','Mode splitting',...
                'Intrinsic','Extrinsic'});
            addFit(this,'Gorodetsky2000plus',...
                ['(a+c*x+d*x.^2+e*x.^2)*abs( (k0^2/4 - kex^2/4 + gamma^2/4 - (x-b).^2 + i*k0.*(x-b))',...
                './( (k0 + kex)^2/4 + gamma^2/4 - (x-b).^2 + i.*(x-b)*(k0 + kex) )).^2+f'],...
                ['$$\left[a+cx+dx^2\right]\left|\frac{\kappa_0^2/4-\kappa_{ex}^2/4+\gamma^2/4-(x-b)^2+i\kappa_0(x-b)/2}',...
                '{(\kappa_0+\kappa_{ex})^2/4+\gamma^2/4-(x-b)^2+i(x-b)(\kappa_0+\kappa_{ex})}\right|^2$$'],...
                { 'a','b','c','d','e','f','gamma','k0', 'kex'},...
                {'Baseline','Center','Lin. Coeff','Quad. Coeff','Cubic Coeff.',...
                'Background','Mode splitting','Intrinsic','Extrinsic'});
            
        end
        
        %Adds a fit to the list of fits. See above for real examples
        %fit_function: the function used to fit to in MATLAB form
        %fit_tex: the fit function written in tex for display in the GUI
        %fit_params: the fit parameters
        %fit_param_names: longer names of fit parameters for GUI
        function addFit(this,fit_name,fit_function,fit_tex,fit_params,...
                fit_param_names)
            this.FitStruct.(fit_name).fit_function=fit_function;
            this.FitStruct.(fit_name).fit_tex=fit_tex;
            this.FitStruct.(fit_name).fit_params=fit_params;
            this.FitStruct.(fit_name).fit_param_names=fit_param_names;
            %Generates the anonymous fit function from the above
            args=['@(x,', strjoin(fit_params,','),')'];
            this.FitStruct.(fit_name).anon_fit_fun=...
                str2func(vectorize([args,fit_function]));
        end
        
        %Updates the GUI if the edit or slider boxes are changed from
        %elsewhere.
        function updateGui(this)
            for i=1:this.n_params
                str=this.fit_params{i};
                set(this.Gui.(sprintf('Edit_%s',str)),...
                    'String',sprintf('%3.3e',this.init_params(i)));
                set(this.Gui.(sprintf('Lim_%s_upper',str)),...
                    'String',sprintf('%3.3e',this.lim_upper(i)))
                set(this.Gui.(sprintf('Lim_%s_lower',str)),...
                    'String',sprintf('%3.3e',this.lim_lower(i)))
            end
        end
        
        %Checks if the class is ready to perform a fit
        function bool=validateData(this)
            bool=~isempty(this.Data.x) && ~isempty(this.Data.y) && ...
                length(this.Data.x)==length(this.Data.y) && ...
                length(this.Data.x)>=this.n_params;
        end
    end
    
    % Set function for nondependent variable
    methods
        %Set function for fit_name.
        function set.fit_name(this,fit_name)
            assert(ischar(fit_name),'The fit name must be a string');
            %Capitalizes the first letter
            fit_name=[upper(fit_name(1)),lower(fit_name(2:end))];
            %Checks it is a valid fit name
            ind=strcmpi(fit_name,this.valid_fit_names);%#ok<MCSUP>
            assert(any(ind),'%s is not a supported fit name',fit_name);
            
            this.fit_name=this.valid_fit_names{ind}; %#ok<MCSUP>
        end
    end
    
    % Get functions for dependent variables
    methods
        %Generates the valid fit names
        function valid_fit_names=get.valid_fit_names(this)
            valid_fit_names=fieldnames(this.FitStruct);
        end
        
        %Grabs the correct fit function from FitStruct
        function fit_function=get.fit_function(this)
            fit_function=this.FitStruct.(this.fit_name).fit_function;
        end
        
        %Grabs the correct tex string from FitStruct
        function fit_tex=get.fit_tex(this)
            fit_tex=this.FitStruct.(this.fit_name).fit_tex;
        end
        
        %Grabs the correct anon fit function from FitStruct
        function anon_fit_fun=get.anon_fit_fun(this)
            anon_fit_fun=this.FitStruct.(this.fit_name).anon_fit_fun;
        end
        
        
        %Grabs the correct fit parameters from FitStruct
        function fit_params=get.fit_params(this)
            fit_params=this.FitStruct.(this.fit_name).fit_params;
        end
        
        %Grabs the correct fit parameter names from FitStruct
        function fit_param_names=get.fit_param_names(this)
            fit_param_names=this.FitStruct.(this.fit_name).fit_param_names;
        end

        %Calculates the number of parameters in the fit function
        function n_params=get.n_params(this)
            n_params=length(this.fit_params);
        end
        
        %Generates a vector of x values for plotting
        function x_vec=get.x_vec(this)
            x_vec=linspace(min(this.Data.x),max(this.Data.x),1e3);
        end
        
        %Used when creating the UserGUI, finds the number of user fields.
        function n_user_fields=get.n_user_fields(this)
            n_user_fields=length(this.user_field_tags);
        end
        
        %Finds all the user field tags
        function user_field_tags=get.user_field_tags(this)
            user_field_tags=fieldnames(this.UserGui.Fields);
        end
        
        %Finds all the titles of the user field tags
        function user_field_names=get.user_field_names(this)
            user_field_names=cellfun(@(x) this.UserGui.Fields.(x).title,...
                this.user_field_tags,'UniformOutput',0);
        end
        
        %Finds all the values of the user fields
        function user_field_vals=get.user_field_vals(this)
            user_field_vals=cellfun(@(x) this.(x), this.user_field_tags);
        end
        
        %Generates a full path for saving
        function fullpath=get.fullpath(this)
            fullpath=[this.save_path,this.filename,'.txt'];
        end
        
        %Generates a base path for saving
        function save_path=get.save_path(this)
            save_path=createSessionPath(this.base_dir,this.session_name);
        end
    end
    
    %Set and get functions for dependent variables with SetAccess
    methods
        %Gets the base dir from the gui
        function base_dir=get.base_dir(this)
            if this.enable_gui
                base_dir=this.Gui.BaseDir.String;
            else
                base_dir=this.SaveInfo.base_dir;
            end
        end
        
        function set.base_dir(this,base_dir)
            if this.enable_gui
                this.Gui.BaseDir.String=base_dir;
            else
                this.SaveInfo.base_dir=base_dir;
            end
        end
        
        function session_name=get.session_name(this)
            if this.enable_gui
                session_name=this.Gui.SessionName.String;
            else
                session_name=this.SaveInfo.session_name;
            end
        end
        
        function set.session_name(this,session_name)
            if this.enable_gui
                this.Gui.SessionName.String=session_name;
            else
                this.SaveInfo.session_name=session_name;
            end
        end
        
        function filename=get.filename(this)
            if this.enable_gui
                filename=this.Gui.FileName.String;
            else
                filename=this.SaveInfo.filename;
            end
        end
        
        function set.filename(this,filename)
            if this.enable_gui
                this.Gui.FileName.String=filename;
            else
                this.SaveInfo.filename=filename;
            end
        end
    end
end