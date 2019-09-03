% Class that implements fitting routines with GUI capabilities.

classdef MyFit < dynamicprops & matlab.mixin.CustomDisplay
    
    properties (Access = public)
        
        % MyTrace object contains the data to be fitted to
        Data    MyTrace    
        
        lim_lower           % Lower limits for fit parameters
        lim_upper           % Upper limits for fit parameters
        
        % If enabled, plots fit curve in the Axes every time the parameter 
        % values are updated
        enable_plot             
        
        fit_color = 'black'   % Color of the fit line
        fit_length = 1e3      % Number of points in the fit trace  
    end
    
    properties (GetAccess = public, SetAccess = protected)
        Axes                % The handle which the fit is plotted in
        Fit                 % MyTrace object containing the fit
        Gui = struct()      % Handles of GUI elements
        
        % Array of cursors with length=2 for the selection of fitting range 
        RangeCursors     MyCursor    
        
        % Output structures from fit() function:
        FitResult   cfit
        Gof         struct
        FitInfo     struct
        
        param_vals  % Numeric values of fit parameters 
        
        fit_name 
        fit_tex         % tex representation of the fit formula 
        fit_function    % fit formula as character string
        fit_params      % character names of fit parameters in fit_function
        fit_param_names % long informative names of fit parameters
        anon_fit_fun    % fit expression represented by anonimous function
        
        % Additional parameters that are calculated from the fit parameters
        % or inputed externally. Properties of user parameters including 
        % long name and write attribute
        UserParamList = struct()
    end
     
    properties (Dependent = true, GetAccess = public)
        n_params
        
        % Indices of data points selected for fitting
        data_selection
        
        % Enable cursors for the selection of fit range   
        enable_range_cursors 
    end
    
    properties (Access = protected)
        enable_gui = 1
        
        % Vectors for varying the range of the sliders in GUI
        slider_vecs
    end
    
    % Events for communicating with outside entities
    events
        NewFit          % Triggered any time fitting is performed
        NewAcceptedFit  % Triggered when fitting is accepted by the user
    end
    
    methods (Access = public)
        function this = MyFit(varargin)
            
            % Parse the arguments supplied to the constructor
            p = inputParser();
            addParameter(p, 'fit_name', '')
            addParameter(p, 'fit_function', 'x')
            addParameter(p, 'fit_tex', '')
            addParameter(p, 'fit_params', {})
            addParameter(p, 'fit_param_names', {})
            addParameter(p, 'Data', MyTrace());
            addParameter(p, 'x', []);
            addParameter(p, 'y', []);
            addParameter(p, 'Axes', [], @isaxes);
            addParameter(p, 'enable_gui', true);
            addParameter(p, 'enable_plot', true);
            addParameter(p, 'enable_range_cursors', false)
            
            % The parameters below are only active when GUI is enabled
            
            % If true, adds save trace panel to the fit gui 
            addParameter(p,'save_panel',true,@islogical);
    
            addParameter(p,'base_dir', '');
            addParameter(p,'session_name','placeholder');
            addParameter(p,'file_name','placeholder');
            
            parse(p, varargin{:});
            
            for i=1:length(p.Parameters)
                
                % Takes the value from the inputParser to the appropriate
                % property.
                if isprop(this, p.Parameters{i})
                    this.(p.Parameters{i}) = p.Results.(p.Parameters{i});
                end
            end
            
            this.Fit = MyTrace();
            
            %Generates the anonymous fit function from the input fit
            %function. This is used for fast plotting of the initial
            %values.
            args=['@(', strjoin([{'x'}, this.fit_params], ','),')'];
            this.anon_fit_fun=...
                str2func(vectorize([args,this.fit_function]));
            
            %Sets dummy values for the GUI
            this.param_vals=zeros(1,this.n_params);
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
            createUserParamList(this);
            
            %Creates the gui if the flag is enabled. This function is in a
            %separate file.
            if this.enable_gui
                createGui(this, 'save_panel', p.Results.save_panel)
                
                %Generates the slider lookup table
                genSliderVecs(this);
                
                if isempty(p.Results.base_dir)
                    try
                        bd = getLocalSettings('measurement_base_dir');
                    catch ME
                        warning(ME.message)
                        bd = '';
                    end
                else
                    bd = '';
                end
                
                this.Gui.BaseDir.String = bd;
                this.Gui.SessionName.String = p.Results.session_name;
                this.Gui.FileName.String = p.Results.file_name;
            end
            
            if ~isempty(this.Axes)
                
                % Add two vertical cursors to the axes
                xlim = this.Axes.XLim;
                x1 = xlim(1)+0.1*(xlim(2)-xlim(1));
                x2 = xlim(2)-0.1*(xlim(2)-xlim(1));
                
                this.RangeCursors = ...
                    [MyCursor(this.Axes, x1, 'orientation', 'vertical', ...
                    'Label','Fit range 1', 'Color', [0.6, 0, 0]),...
                    MyCursor(this.Axes, x2, 'orientation', 'vertical', ...
                    'Label','Fit range 2', 'Color', [0.6, 0, 0])];
                
                % Enabling/disabling of the cursors by setting the class 
                % property can be done only after the cursors are
                % initialized
                this.enable_range_cursors = p.Results.enable_range_cursors;
            end
            
            %If data was supplied, generates initial fit parameters
            if ~isDataEmpty(this.Data) 
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
            
            if ismethod(this.Fit, 'delete')
                
                % Delete the fit trace, in particular, in order to remove 
                % the fit curve from the axes
                delete(this.Fit); 
            end
            
            if ~isempty(this.RangeCursors)
                delete(this.RangeCursors);
            end
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
                save_data=[save_data,this.user_field_vals']
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
            
            fullpath=[this.save_path,this.filename,'.txt'];
            
            %We automatically append to the file if it already exists,
            %otherwise create a new file
            if exist(fullpath,'file')
                fileID=fopen(fullpath,'a');
                fprintf('Appending data to %s \n',fullpath);
            else
                fileID=fopen(fullpath,'w');
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
            p=inputParser
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
            
            %Perform the fit with current parameters as a starting point
            ind = this.data_selection;
            this.param_vals = doFit(this, ...
                this.Data.x(ind), this.Data.y(ind), this.param_vals, ...
                this.lim_lower, this.lim_upper);
            
            %Calculate the fit curve
            calcFit(this);
            
            %Calculate user parameters that depend on the fit parameters
            calcUserParams(this);
            
            %Update fit metadata
            this.Fit.UserMetadata = createMetadata(this);
            
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
            cellfun(@(x) delete(x), this.Fit.PlotLines);
        end
        
        %Plots the trace contained in the Fit MyTrace object 
        function plotFit(this, varargin)
            plot(this.Fit, this.Axes, 'Color', this.fit_color, varargin{:});
        end
        
        %Generates model-dependent initial parameters, lower and upper
        %boundaries.
        function genInitParams(this)
            validateData(this);
            
            calcInitParams(this);
            calcFit(this);
            calcUserParams(this);
            
            %Plots the fit function with the new initial parameters
            if this.enable_plot 
                plotFit(this) 
            end
            
            %Updates the GUI and creates new lookup tables for the init
            %param sliders
            if this.enable_gui
                genSliderVecs(this);
                updateGui(this);
            end
        end
               
        %Triggers the NewFit event such that other objects can use this to
        %e.g. plot new fits
        function triggerNewFit(this)
            notify(this,'NewFit');
        end
        
        function triggerNewAcceptedFit(this)
            notify(this,'NewAcceptedFit');
        end
        
        % Create metadata with all the fitting and user-defined parameters
        function Mdt = createMetadata(this)
            
            % Field for the fit parameters
            InfoMdt = MyMetadata('title', 'FitInfo');
            
            addObjProp(InfoMdt, this, 'fit_name');
            addObjProp(InfoMdt, this, 'fit_function');
            
            % Indicate if the parameter values were obtained manually or
            % from performing a fit
            if isempty(this.Gof)
                param_val_mode = 'manual';
            else
                param_val_mode = 'fit';
            end
            
            addParam(InfoMdt, 'param_val_mode', param_val_mode, ...
                'comment', ['If the parameter values were set manually '...
                'or obtained from fit']);
            
            % Field for the fit parameters
            ParValMdt = MyMetadata('title', 'FittingParameters');
            
            if ~isempty(this.Gof)
                
                % Add fit parameters with confidence intervals
                ci = confint(this.FitResult, 0.95);
 
                for i=1:length(this.fit_params)
                    str = sprintf('%8.4g  (%.4g, %.4g)', ...
                        this.param_vals(i), ci(1,i), ci(2,i));
                    
                    addParam(ParValMdt, this.fit_params{i}, str, ...
                        'comment', [this.fit_param_names{i} ...
                        ' (95% confidence interval)']);
                end
            else
                
                % Add only fit parameters
                for i=1:length(this.fit_params)
                    addParam(ParValMdt, this.fit_params{i}, ...
                        this.param_vals(i), 'comment', ...
                        this.fit_param_names{i});
                end
            end
            
            user_params = fieldnames(this.UserParamList);
            if ~isempty(user_params)
                
                % Add a field with the user parameters
                UserParMdt = MyMetadata('title', 'UserParameters');
                for i=1:length(user_params)
                    tag = user_params{i};
                    addParam(UserParMdt, tag, this.(tag), ...
                        'comment', this.UserParamList.(tag).title);
                end
            else
                UserParMdt = MyMetadata.empty();
            end
            
            if ~isempty(this.Gof)
                
                % Field for the goodness of fit which copies the fields of
                % corresponding structure
                GofMdt = MyMetadata('title', 'GoodnessOfFit');

                addParam(GofMdt, 'sse', this.Gof.sse, 'comment', ...
                    'Sum of squares due to error');
                addParam(GofMdt, 'rsquare', this.Gof.rsquare, 'comment',...
                    'R-squared (coefficient of determination)');
                addParam(GofMdt, 'dfe', this.Gof.dfe, 'comment', ...
                    'Degrees of freedom in the error');
                addParam(GofMdt, 'adjrsquare', this.Gof.adjrsquare, ...
                    'comment', ['Degree-of-freedom adjusted ' ...
                    'coefficient of determination']);
                addParam(GofMdt, 'rmse', this.Gof.rmse, 'comment', ...
                    'Root mean squared error (standard error)');
            else
                GofMdt = MyMetadata.empty();
            end
            
            Mdt = [InfoMdt, ParValMdt, UserParMdt, GofMdt];
        end
    end
    
    methods (Access = protected)
        
        %Creates the GUI of MyFit, in separate file.
        createGui(this, varargin);
        
        %Does the fit with the currently set parameters. This method is 
        %often overloaded in subclasses to improve performance.
        function fitted_vals = doFit(this, x, y, init_vals, lim_lower, ...
                lim_upper)

            %Fits with the below properties. Chosen for maximum accuracy.
            Ft = fittype(this.fit_function,'coefficients',this.fit_params);
            Opts = fitoptions('Method','NonLinearLeastSquares',...
                'Lower',        lim_lower,...
                'Upper',        lim_upper,...
                'StartPoint',   init_vals,...
                'MaxFunEvals',  2000,...
                'MaxIter',      2000,...
                'TolFun',       1e-6,...
                'TolX',         1e-6);
            
            [this.FitResult, this.Gof, this.FitInfo] = fit(x, y, Ft, Opts);
            
            %Return the coefficients 
            fitted_vals = coeffvalues(this.FitResult);
        end
        
        %Low level function that generates initial parameters. 
        %The default version of this function is not meaningful, it
        %should be overloaded in subclasses.
        function calcInitParams(this)
            this.param_vals=ones(1,this.n_params);
            this.lim_lower=-Inf(1,this.n_params);
            this.lim_upper=Inf(1,this.n_params);
        end
        
        % Calculate user parameters from fit parameters.
        % Dummy method that needs to be overloaded in subclasses.
        function calcUserParams(this) %#ok<MANU>
        end
        
        function addUserParam(this, name, varargin)
            
            % Process inputs
            p = inputParser();
            addRequired(p, 'name', @ischar);
            addParameter(p, 'title', '');
            addParameter(p, 'editable', @(x)assert(isequal(x, 'on') || ...
                isequal(x, 'off'), ['''editable'' property must be ' ...
                '''on'' or ''off''']));
            addParameter(p, 'default', []);
            
            parse(p, name, varargin{:});
            
            % Store the information about the user parameter
            this.UserParamList.(name).title = p.Results.title;
            this.UserParamList.(name).editable = p.Results.editable;
            
            % Create a dynamic property for easy access
            Mp = addprop(this, name);
            this.UserParamList.(name).Metaprop = Mp;
            
            Mp.GetAccess = 'public';
            
            if ~isempty(p.Results.default)
                this.(name) = p.Results.default;
            end
            
            if this.UserParamList.(name).editable
                Mp.SetAccess = 'public';
            else
                Mp.SetAccess = 'private';
            end
        end
        
        % addUserParam statements must be contained in this function
        % overloaded in subclasses.
        function createUserParamList(this) %#ok<MANU>
        end
        
        function genSliderVecs(this)
            %Return values of the slider
            slider_vals=1:101;
            %Default scaling vector
            def_vec=10.^((slider_vals-51)/50);
            %Sets the cell to the default value
            for i=1:this.n_params
                this.slider_vecs{i}=def_vec*this.param_vals(i);
                set(this.Gui.(sprintf('Slider_%s', this.fit_params{i})),...
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
            xmin = this.Data.x(1);
            xmax = this.Data.x(end);
            
            if this.enable_range_cursors
                
                % If range cursors are active, restrict to the selected
                % range
                xmin = max(xmin, min(this.RangeCursors.value));
                xmax = min(xmax, max(this.RangeCursors.value));
            end
            
            this.Fit.x=linspace(xmin, xmax, this.fit_length);
            input_coeffs=num2cell(this.param_vals);
            this.Fit.y=this.anon_fit_fun(this.Fit.x, input_coeffs{:});
        end
        
        %Overload a method of matlab.mixin.CustomDisplay in order to
        %separate the display of user properties from the others.
        function PrGroups = getPropertyGroups(this)
            user_params = fieldnames(this.UserParamList);
            static_props = setdiff(properties(this), user_params);
            
            PrGroups = [matlab.mixin.util.PropertyGroup(static_props), ...
                matlab.mixin.util.PropertyGroup(user_params)];
        end
    end
    
    %Callbacks
    methods (Access = protected)
        
        %Callback for saving the fit trace
        function saveFitCallback(this,~,~)
            base_dir=this.Gui.BaseDir.String;
            session_name=this.Gui.SessionName.String;
            file_name=this.Gui.FileName.String;
            
            % Add extension to the file name if missing
            [~,~,ext]=fileparts(file_name);  
            if isempty(ext) || (length(ext) > 5) || any(isspace(ext))
                file_name=[file_name, '.txt'];
            end
            
            assert(~isempty(base_dir),'Save directory is not specified');
            save_path=createSessionPath(base_dir, session_name);
            save(this.Fit, fullfile(save_path, file_name));
        end
        
        %Creates callback functions for sliders in GUI. Uses ind to find 
        %out which slider the call is coming from. Note that this gets 
        %triggered whenever the value of the slider is changed.
        function f = createSliderStateChangedCallback(this, ind)
            edit_field_name = sprintf('Edit_%s',this.fit_params{ind});
            
            function sliderStateChangedCallback(hObject, ~)
                %Gets the value from the slider
                val=hObject.Value;

                %Find out if the current slider value is correct for the
                %current init param value. If so, do not change anything. 
                %This is required as the callback also gets called when 
                %the slider values are changed programmatically
                [~, slider_ind]=...
                    min(abs(this.param_vals(ind)-this.slider_vecs{ind}));
                
                if slider_ind~=(val+1)
                    %Updates the scale with a new value from the lookup 
                    %table
                    this.param_vals(ind)=...
                        this.slider_vecs{ind}(val+1);
                    %Updates the edit box with the new value from the 
                    %slider
                    set(this.Gui.(edit_field_name),...
                        'String', sprintf('%3.3e',this.param_vals(ind)));

                    %Re-calculate the fit curve.
                    calcFit(this);

                    if this.enable_plot
                        plotFit(this); 
                    end
                end
            end
            
            f = @sliderStateChangedCallback;
        end
        
        function f = createParamFieldEditedCallback(this, ind)
            function paramEditFieldCallback(hObject, ~)
                val=str2double(hObject.String);
                manSetParamVal(this, ind, val);
            end
            
            f = @paramEditFieldCallback;
        end
        
        function f = createSliderMouseReleasedCallback(this, ind)
            function sliderMouseReleasedCallback(hObject, ~)
                slider_ind=hObject.Value;
                val = this.slider_vecs{ind}(slider_ind+1);
                manSetParamVal(this, ind, val);
            end
            
            f = @sliderMouseReleasedCallback;
        end
        
        %Callback function for the manual update of the values of fit 
        %parameters in GUI. Triggered when values in the boxes are editted
        %and when pulling a slider is over.
        function manSetParamVal(this, ind, new_val)
            
            %Updates the correct initial parameter
            this.param_vals(ind)=new_val;
            
            %Re-calculate the fit curve.
            calcFit(this);
                
            if this.enable_plot
                plotFit(this)
            end
            
            %Centers the slider
            set(this.Gui.(sprintf('Slider_%s',this.fit_params{ind})),...
                'Value',50);
            
            %Generate the new slider vectors
            genSliderVecs(this);
            
            %Reset fit structures to indicate that the current parameters
            %were set manually
            this.FitResult=cfit.empty();
            this.Gof=struct.empty();
            this.FitInfo=struct.empty();
            
            %Calculate user parameters
            calcUserParams(this);
            
            %Update fit metadata
            this.Fit.UserMetadata=createMetadata(this);
        end
        
        function f = createLowerLimEditCallback(this, ind)
            function lowerLimEditCallback(hObject, ~)
                this.lim_lower(ind)=str2double(hObject.String);
            end
            
            f = @lowerLimEditCallback;
        end
        
        function f = createUpperLimEditCallback(this, ind)
            function upperLimEditCallback(hObject, ~)
                this.lim_upper(ind)=str2double(hObject.String);
            end
            
            f = @upperLimEditCallback;
        end
        
        %Create a callback that is executed when an editable user parameter 
        %is set in the GUI
        function f = createUserParamCallback(this, param_name)
            function userParamCallback(hObject, ~)
                this.(param_name) = str2double(hObject.String);
                calcUserParams(this);
            end
            
            f = @userParamCallback; 
        end
        
        %Callback function for analyze button in GUI. Checks if the data is
        %ready for fitting.
        function analyzeCallback(this, ~, ~)
            fitTrace(this);
        end
        
        function acceptFitCallback(this, ~, ~)
            triggerNewAcceptedFit(this);
        end
        
        function enableCursorsCallback(this, hObject, ~)
            this.enable_range_cursors = hObject.Value;
        end
        
        %Callback for clearing the fits on the axis.
        function clearFitCallback(this, ~, ~)
            clearFit(this);
        end
        
        %Callback function for the button that generates init parameters.
        function initParamCallback(this, ~, ~)
            genInitParams(this);
        end
        
        %Close figure callback simply calls delete function for class
        function closeFigureCallback(this,~,~)
            delete(this);
        end
    end
    
    %Private methods
    methods(Access = private)
        
        %Creates a panel for the GUI, in separate file
        createUserControls(this, varargin);
        
        %Updates the GUI if the edit or slider boxes are changed from
        %elsewhere.
        function updateGui(this)
            for i=1:this.n_params
                str=this.fit_params{i};
                set(this.Gui.(sprintf('Edit_%s',str)),...
                    'String',sprintf('%3.3e',this.param_vals(i)));
                set(this.Gui.(sprintf('Lim_%s_upper',str)),...
                    'String',sprintf('%3.3e',this.lim_upper(i)));
                set(this.Gui.(sprintf('Lim_%s_lower',str)),...
                    'String',sprintf('%3.3e',this.lim_lower(i)));
            end
        end
    end
    
    methods
        
        % Can set enable_plot to true only if Axes are present
        function set.enable_plot(this, val)
            val = logical(val);
            this.enable_plot = val & ~isempty(this.Axes); %#ok<MCSUP>
        end
        
        function set.enable_range_cursors(this, val)
            if ~isempty(this.RangeCursors)
                for i=1:length(this.RangeCursors)
                    this.RangeCursors(i).Line.Visible = val;
                end
            end
            
            try
                if this.enable_gui && ...
                        this.Gui.CursorsCheckbox.Value ~= val
                    this.Gui.CursorsCheckbox.Value = val;
                end
            catch
            end
        end
        
        % Visibility of the range cursors is the reference if they are
        % enabled or not
        function val = get.enable_range_cursors(this)
            if ~isempty(this.RangeCursors)
                val = strcmpi(this.RangeCursors(1).Line.Visible, 'on');
            else
                val = false;
            end
        end
        
        function ind = get.data_selection(this)
            if this.enable_range_cursors
                xmin = min(this.RangeCursors.value);
                xmax = max(this.RangeCursors.value);
                ind = (this.Data.x>xmin & this.Data.x<=xmax);
            else
                ind = true(1, length(this.Data.x));
            end
        end
        
        %Calculates the number of parameters in the fit function
        function n_params=get.n_params(this)
            n_params=length(this.fit_params);
        end
    end
end