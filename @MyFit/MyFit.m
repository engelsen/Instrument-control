classdef MyFit < dynamicprops
    %Note that dynamicprops classes are handle classes.
    properties (Access=public)
        Data;           %MyTrace object contains the data to be fitted to
        
        lim_lower;      %Lower limits for fit parameters
        lim_upper;      %Upper limits for fit parameters
        
        enable_plot;    %If enabled, plots initial parameters in the Axes
        
        Axes;           %The handle which the fit is plotted in
        fit_color='c';  %Color of the fit line
        fit_length=1e3; %Number of points in the fit trace
    end
    
    properties (GetAccess=public, SetAccess=protected)
        Fit; %MyTrace object containing the fit
        
        Gui; %Gui handles
        
        %Output structures from fit:
        Fitdata;
        Gof;
        FitInfo;
        param_vals; %Values of fit parameters
        
        %Parameters of the specific fit.
        fit_name;
        fit_function;
        fit_tex;
        fit_params;
        fit_param_names;
        anon_fit_fun;
    end
    
    properties (Access=protected)
        %Structure used for initializing GUI of userpanel
        UserGui;
        Parser; %Input parser for constructor
        enable_gui=1;
        
        %Private struct used for saving file information when there is no
        %gui
        SaveInfo
        slider_vecs; %Vectors for varying the range of the sliders for different fits
    end
    
    %Dependent variables with no set methods
    properties (Dependent=true, SetAccess=private)
        n_params;
        
        %Variables used for saving, linked to the GUI
        fullpath;
        save_path;
    end
    
    properties (Dependent=true, Access=protected)
        %These are used to create the usergui
        n_user_fields;
        user_field_tags;
        user_field_names;
        user_field_vals;
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
    
    methods (Access=public)
        function this=MyFit(varargin)
            %Sets the default parameters for the save directory and
            %filename.
            this.SaveInfo.filename='placeholder';
            this.SaveInfo.session_name='placeholder';
            this.SaveInfo.base_dir=getLocalSettings('measurement_base_dir');
            
            %We now create the parser for parsing the arguments to the
            %constructor, and parse the variables.
            p=inputParser;
            addParameter(p,'fit_name','')
            addParameter(p,'fit_function','x')
            addParameter(p,'fit_tex','')
            addParameter(p,'fit_params',{})
            addParameter(p,'fit_param_names',{})
            addParameter(p,'Data', MyTrace());
            addParameter(p,'x',[]);
            addParameter(p,'y',[]);
            addParameter(p,'enable_gui',1);
            addParameter(p,'enable_plot',1);
            addParameter(p,'Axes',[]);
            addParameter(p,'base_dir',this.SaveInfo.filename);
            addParameter(p,'session_name',this.SaveInfo.session_name);
            addParameter(p,'filename',this.SaveInfo.base_dir);
            
            parse(p, varargin{:});
            
            for i=1:length(p.Parameters)
                %Takes the value from the inputParser to the appropriate
                %property.
                if isprop(this, p.Parameters{i})
                    this.(p.Parameters{i})= p.Results.(p.Parameters{i});
                end
            end
            
            %Generates the anonymous fit function from the input fit
            %function. This is used for fast plotting of the initial
            %values.
            args=['@(', strjoin([{'x'}, this.fit_params], ','),')'];
            this.anon_fit_fun=...
                str2func(vectorize([args,this.fit_function]));
            
            %Sets dummy values for the GUI
            this.lim_lower=-Inf(1,this.n_params);
            this.lim_upper=Inf(1,this.n_params);
            
            %Allows us to load either x/y data or a MyTrace object directly
            if ismember('Data',p.UsingDefaults) &&...
                    ~ismember('x',p.UsingDefaults) &&...
                    ~ismember('y',p.UsingDefaults)
                
                this.Data.x=p.Results.x;
                this.Data.y=p.Results.y;
            end
            
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
            
            %If data was supplied, generates initial fit parameters
            if ~ismember('Data', p.UsingDefaults) || ...
                    ~ismember('x', p.UsingDefaults) || ...
                    ~ismember('y', p.UsingDefaults) 
                genInitParams(this) 
            end
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
            if ~isempty(this.Fit.hlines); 
                delete(this.Fit.hlines{:}); 
            end
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
            
            assert(~isempty(this.param_vals) && ...
                length(this.param_vals)==this.n_params,...
                ['The number of calculated coefficients (%i) is not',...
                ' equal to the number of parameters (%i).', ...
                ' Perform a fit before trying to save parameters.'],...
                length(this.param_vals),this.n_params);
            
            %Creates combined strings of form: Linewidth (b), where
            %Linewidth is the parameter name and b is the parameter tag
            headers=cellfun(@(x,y) sprintf('%s (%s)',x,y),...
                this.fit_param_names, this.fit_params,'UniformOutput',0);
            save_data=this.param_vals;
            
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
                this.param_vals(i)=load_table.(load_names{i})(n);
            end
        end
        
        %This function is used to set the coefficients, to avoid setting it
        %to a number not equal to the number of parameters
        function setFitParams(this,param_vals)
            assert(length(param_vals)==this.n_params,...
                ['The length of the coefficient vector (currently %i) ',...
                'must be equal to the number of parameters (%i)'],...
                length(this.param_vals),this.n_params)
            this.param_vals=param_vals;
        end
        
        %Fits the trace using currently set parameters, depending on the
        %model.
        function fitTrace(this)
            
            %Check the validity of data
            validateData(this);
            
            %Check for valid limits
            lim_check=this.lim_upper>this.lim_lower;
            assert(all(lim_check),...
                sprintf(['All upper limits must exceed lower limits. ',...
                'Check limit %i, fit parameter %s'],find(~lim_check,1),...
                this.fit_params{find(~lim_check,1)}));
            
            %Check the consistency of initial parameters
            assert(isnumeric(this.param_vals) && isvector(this.param_vals) && ...
                length(this.param_vals)==this.n_params, ['Starting points must be given as ' ...
                'a vector of size %d'],this.n_params);
            assert(isnumeric(this.lim_lower) && isvector(this.lim_lower) && ...
                length(this.lim_lower)==this.n_params, ['Lower limits must be given as ' ...
                'a vector of size %d'], this.n_params);
            assert(isnumeric(this.lim_upper) && isvector(this.lim_upper) && ...
                length(this.lim_upper)==this.n_params, ['Upper limits must be given as ' ...
                'a vector of size %d'], this.n_params);
            
            %Perform the fit.
            doFit(this);
            
            %Calculate the fit curve.
            calcFit(this);
            
            %Updates the gui if it is enabled
            if this.enable_gui
                genSliderVecs(this);
                updateGui(this);
            end
            
            %Plots the fit if the flag is on
            if this.enable_plot 
                plotFit(this); 
            end
            
            %Triggers new fit event
            triggerNewFit(this);
        end
        
        %Clears the plots
        function clearFit(this)
            cellfun(@(x) delete(x), this.Fit.hlines);
            this.Fit.hlines={}
        end
        
        %Plots the trace contained in the Fit MyTrace object after
        %calculating the new values
        function plotFit(this, varargin)
            assert((isa(this.Axes,'matlab.graphics.axis.Axes')||...
                isa(this.Axes,'matlab.ui.control.UIAxes')),...
                'Axes property must be defined to valid axis in order to plot')
            
            plot(this.Fit, this.Axes, varargin{:});
        end
        
        %Function for plotting fit model with current initial parameters.
        function plotInitFun(this)
            %Substantially faster than any alternative - generating
            %anonymous functions is very cpu intensive.
            
            input_cell=num2cell(this.init_params)
            y_vec=feval(this.anon_fit_fun,...
                this.x_vec,input_cell{:})
            if isempty(this.hline_init)
                this.hline_init=plot(this.Axes,this.x_vec,y_vec,...
                    'Color',this.fit_color)
            else
                a=
                set(this.hline_init,'XData',this.x_vec,'YData',y_vec);
            end
        end
        
        %Generates model-dependent initial parameters, lower and upper
        %boundaries.
        function genInitParams(this)
            validateData(this);
            
            %Cell for putting parameters in to be interpreted in the
            %parser. Element 1 contains the init params, Element 2 contains
            %the lower limits and Element 3 contains the upper limits.
            params=cell(1,3);
            
            [params{1},params{2},params{3}]=calcInitParams(this);
            
            %For the ease of debugging, validate the calculated parameters 
            %using parser. I.e. check that the number of generated 
            %parameters is correct and that all of them fall into the 
            %specified limits. 
            n_arg = this.n_params;
            
            p=inputParser()
            validateStart=@(x) assert(isnumeric(x) && isvector(x) && ...
                length(x)==n_arg, ['Starting points must be given as ' ...
                'a vector of size %d'],n_arg);
            validateLower=@(x) assert(isnumeric(x) && isvector(x) && ...
                length(x)==n_arg, ['Lower limits must be given as ' ...
                'a vector of size %d'],n_arg);
            validateUpper=@(x) assert(isnumeric(x) && isvector(x) && ...
                length(x)==n_arg, ['Upper limits must be given as ' ...
                'a vector of size %d'], n_arg);

            addOptional(p,'init_params',ones(1,n_arg),validateStart)
            addOptional(p,'lower',-Inf*ones(1,n_arg),validateLower)
            addOptional(p,'upper',Inf*ones(1,n_arg),validateUpper)

            parse(p, params{:});
            
            %Loads the parsed results into the class variables
            this.init_params=p.Results.init_params;
            this.lim_lower=p.Results.lower;
            this.lim_upper=p.Results.upper
            
            %Plots the fit function with the new initial parameters
            if this.enable_plot 
                plotInitFun(this) 
            end
            
            %Updates the GUI and creates new lookup tables for the init
            %param sliders
            if this.enable_gui
                genSliderVecs(this);
                updateGui(this);
            end
        end
    end
    
    methods (Access=protected)
        %Creates the GUI of MyFit, in separate file.
        createGui(this);
        
        %Does the fit with the currently set parameters. This method is 
        %often overloaded in subclasses to improve performance.
        function doFit(this)
            
            %Use current coefficients as initial paramters
            init_params = this.param_vals;
            
            Ft=fittype(this.fit_function,'coefficients',this.fit_params);
            Opts=fitoptions('Method','NonLinearLeastSquares',...
                'Lower',this.lim_lower,...
                'Upper',this.lim_upper,...
                'StartPoint',init_params,...
                'MaxFunEvals',2000,...
                'MaxIter',2000,...
                'TolFun',1e-6,...
                'TolX',1e-6);
            %Fits with the below properties. Chosen for maximum accuracy.
            [this.Fitdata,this.Gof,this.FitInfo]=...
                fit(this.Data.x,this.Data.y,Ft,Opts);
            %Puts the coefficients into the class variable.
            this.param_vals=coeffvalues(this.Fitdata);
        end
        
        %This struct is used to generate the UserGUI. Fields are seen under
        %tabs in the GUI. To create a new tab, you have to enter it under
        %this.UserGui.Tabs. A tab must have a tab_title and a field to add
        %Children. To add a field, use the addUserField function.
        function createUserGuiStruct(this)
            this.UserGui=struct('Fields',struct(),'Tabs',struct());
        end
        
        %Low level function that generates initial parameters. 
        %The default version of this function is not meaningful, it
        %should be overloaded in subclasses.
        function [init_params,lim_lower,lim_upper]=calcInitParams(this)
            init_params=ones(1,this.n_params);
            lim_lower=-Inf(1,this.n_params);
            lim_upper=Inf(1,this.n_params);
            
            %Loads the results into the class variables
            this.param_vals=init_params;
            this.lim_lower=lim_lower;
            this.lim_upper=lim_upper;
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
        
        
        %Creates the user values panel with associated tabs. The cellfun here
        %creates the appropriately named tabs. To add a tab, add a new field to the
        %UserGuiStruct using the class functions in MyFit. This function
        %can be overloaded, though some care must be taken to not exceed
        %the size given by the GUI
        function createUserGui(this, bg_color, button_h)
            usertabs=fieldnames(this.UserGui.Tabs);
            if ~isempty(usertabs)
                cellfun(@(x) createTab(this,x,bg_color,button_h),usertabs);
                this.Gui.TabPanel.TabTitles=...
                    cellfun(@(x) this.UserGui.Tabs.(x).tab_title, usertabs,...
                    'UniformOutput',0);
            end
        end
        
        %Can be overloaded to have more convenient sliders
        function genSliderVecs(this)
            %Return values of the slider
            slider_vals=1:101;
            %Default scaling vector
            def_vec=10.^((slider_vals-51)/50);
            %Sets the cell to the default value
            for i=1:this.n_params
                this.slider_vecs{i}=def_vec*this.param_vals(i);
                set(this.Gui.(sprintf('Slider_%s',this.fit_params{i})),...
                    'Value',50);
            end
        end
        
        %Checks if the class is ready to perform a fit
        function validateData(this)
            assert(~isempty(this.Data.x) && ~isempty(this.Data.y) && ...
                length(this.Data.x)==length(this.Data.y) && ...
                length(this.Data.x)>=this.n_params, ...
                ['The data must be vectors of equal length greater ' ...
                'than the number of fit parameters.', ...
                ' Currently the number of fit parameters is %i, the', ...
                ' length of x is %i and the length of y is %i'], ...
                this.n_params, length(this.Data.x), length(this.Data.y));
        end
        
        %Calculates the trace object that represents the fitted curve
        function calcFit(this)
            this.Fit.x=linspace(min(this.Data.x), max(this.Data.x), ...
                this.fit_length);
            input_coeffs=num2cell(this.param_vals);
            this.Fit.y=this.anon_fit_fun(this.Fit.x,input_coeffs{:});
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
                min(abs(this.param_vals(param_ind)-this.slider_vecs{param_ind}));
            if ind~=(val+1)
                %Updates the scale with a new value from the lookup table
                this.param_vals(param_ind)=...
                    this.slider_vecs{param_ind}(val+1);
                %Updates the edit box with the new value from the slider
                set(this.Gui.(sprintf('Edit_%s',this.fit_params{param_ind})),...
                    'String',sprintf('%3.3e',this.param_vals(param_ind)));
                if this.enable_plot 
                    plotInitFun(this); 
                end
            end
        end
        
        %Callback function for edit boxes in GUI
        function editCallback(this, hObject, ~)
            val=str2double(hObject.String);
            param_ind=str2double(hObject.Tag);
            
            %Centers the slider
            set(this.Gui.(sprintf('Slider_%s',this.fit_params{param_ind})),...
                'Value',50);
            
            %Updates the correct initial parameter
            this.param_vals(param_ind)=val;
            if this.enable_plot
                plotInitFun(this)
            end
            
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
        function scaleDataCallback(this,hObject)
            if hObject.Value
                hObject.BackgroundColor=0.9*[1,1,1];
                this.scale_data=true;
            else
                hObject.BackgroundColor=[1,1,1];
                this.scale_data=false;
            end
        end
    end
    
    %Private methods
    methods(Access=private)
        
        %Creates a panel for the GUI, in separate file
        createTab(this, tab_tag, bg_color, button_h);
        
        %Creats two vboxes (from GUI layouts) to display values of
        %quantities
        createUnitBox(this, bg_color, h_parent, name);
        
        %Creates an edit box inside a UnitDisp for showing label and value of
        %a quantity. Used in conjunction with createUnitBox
        createUnitDisp(this,varargin);
        
        %Triggers the NewFit event such that other objects can use this to
        %e.g. plot new fits
        function triggerNewFit(this)
            notify(this,'NewFit');
        end
        
        %Triggers the NewInitVal event
        function triggerNewInitVal(this)
            notify(this,'NewInitVal');
        end
        
        %Updates the GUI if the edit or slider boxes are changed from
        %elsewhere.
        function updateGui(this)
            for i=1:this.n_params
                str=this.fit_params{i};
                set(this.Gui.(sprintf('Edit_%s',str)),...
                    'String',sprintf('%3.3e',this.param_vals(i)));
                set(this.Gui.(sprintf('Lim_%s_upper',str)),...
                    'String',sprintf('%3.3e',this.lim_upper(i)))
                set(this.Gui.(sprintf('Lim_%s_lower',str)),...
                    'String',sprintf('%3.3e',this.lim_lower(i)))
            end
        end
    end
    
    % Get functions for dependent variables
    methods
        %Calculates the number of parameters in the fit function
        function n_params=get.n_params(this)
            n_params=length(this.fit_params);
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