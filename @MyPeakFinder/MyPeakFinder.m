classdef MyPeakFinder < handle
    properties
        Trace;
        Peaks;
    end
    
    methods
        function this=MyPeakFinder(varargin)
            p=inputParser;
            addParameter(p,'Trace',MyTrace());
            parse(p,varargin{:})
            
            this.Trace=p.Results.Trace;
            this.Peaks=struct('Location',[],'Width',[],'Prominence',[],...
                'Value',[]);
        end
        
        %Checks if a peak exists within the given limits
        function bool=checkPeakExist(this,x_min,x_max)
           assert(isnumeric(x_min) & isnumeric(x_max),...
               'x_min and x_max must be numbers');
           assert(x_max>x_min,['x_max must be greater than x_min,',...
               ' currently x_min is %e while x_max is %e'],x_min,x_max);
           bool=any([this.Peaks.Location]>x_min & [this.Peaks.Location]<x_max);
        end
        
        function searchPeaks(this,varargin)
            assert(validatePlot(this.Trace),...
                'The Trace is not valid for finding peaks, make sure a proper trace is loaded');
            p=inputParser;
            %Some validation functions
            ispositive=@(x) isnumeric(x) && isscalar(x) && (x > 0);
            isnumber=@(x) isnumeric(x) && isscalar(x);
            
            valid_sorts={'none','ascend','descend'};
            sortstrcheck=@(x) any(validatestring(x,valid_sorts));            
            
            addParameter(p,'FindMinima',false);
            addParameter(p,'MinPeakDistance',0,ispositive);
            addParameter(p,'MinPeakHeight',-Inf,isnumber);
            addParameter(p,'MinPeakWidth',0,ispositive);
            addParameter(p,'MaxPeakWidth',Inf,ispositive);
            addParameter(p,'MinPeakProminence',0.1,isnumber);
            addParameter(p,'SortStr','none',sortstrcheck);
            addParameter(p,'Threshold',0);
            addParameter(p,'ClearPeaks',true);
            addParameter(p,'Limits',[min(this.Trace.x),max(this.Trace.x)])
            addParameter(p,'NPeaks',0);
            addParameter(p,'WidthReference','halfprom')
            parse(p,varargin{:});
            
            %Sets the indices to be searched
            x_lim=p.Results.Limits;
            ind=(this.Trace.x<x_lim(2)) & (this.Trace.x>x_lim(1));
            
            %Sets the minimum peak prominence, which is always normalized
            min_peak_prominence=p.Results.MinPeakProminence*...
                peak2peak(this.Trace.y(ind));
            
            %We must condition the Trace such that x is increasing and has
            %no NaNs
            nan_ind=isnan(this.Trace.x) | isnan(this.Trace.y);
            this.Trace.x(nan_ind)=[];
            this.Trace.y(nan_ind)=[];
            ind(nan_ind)=[];
            
            if ~issorted(this.Trace.x)
                this.Trace.x=flipud(this.Trace.x);
                this.Trace.y=flipud(this.Trace.y);
                %If it is still not sorted, we sort it
                if ~issorted(this.Trace.x)
                    'Sorting';
                    [this.Trace.x,sort_ind]=sort(this.Trace.x);
                    this.Trace.y=this.Trace.y(sort_ind);
                end
            end
            
            %If we are looking for minima, we invert the trace
            if p.Results.FindMinima
                y=-this.Trace.y;
            else
                y=this.Trace.y;
            end
            
            %As there is no way to tell it to look for infinite numbers of
            %peaks when you specify NPeaks, we only specify this parameter
            %if we need to
            if p.Results.NPeaks
                extra_args={'NPeaks',p.Results.NPeaks};
            else
                extra_args={};
            end
            
            %We now search for the peaks using the specified parameters
            [pks,locs,wdth,prom]=findpeaks(y(ind),...
                this.Trace.x(ind),...
                'MinPeakDistance',p.Results.MinPeakDistance,...
                'MinPeakheight',p.Results.MinPeakHeight,...
                'MinPeakWidth',p.Results.MinPeakWidth,...
                'MaxPeakWidth',p.Results.MaxPeakWidth,...
                'SortStr',p.Results.SortStr,...
                'MinPeakProminence',min_peak_prominence,...
                'Threshold',p.Results.Threshold,...
                'WidthReference',p.Results.WidthReference,...
                extra_args{:});
            
            %We invert the results back if we are looking for minima.
            if p.Results.FindMinima
                pks=-pks;
                prom=-prom;
            end
            
            PeakStruct=struct('Value',num2cell(pks),...
                'Location',num2cell(locs),...
                'Width',num2cell(wdth),...
                'Prominence',num2cell(prom));
            
            %If the clearpeaks flag is set, we delete the previous peaks.
            if p.Results.ClearPeaks
                clearPeaks(this);
                this.Peaks=PeakStruct;
            else
                this.Peaks=[this.Peaks;PeakStruct];
            end
        end
        
        function loadTrace(this,fullfilename)
             %Finds type of file
            [~,~,ext]=fileparts(fullfilename);
            
            switch ext
                case '.txt'
                    load(this.Trace,fullfilename);
                case '.mat'
                    DataStruct=load(fullfilename);
                    fields=fieldnames(DataStruct);
                    
                    %We try to find which vectors are x and y for the data,
                    %first we find the two longest vectors in the .mat file
                    %and use these
                    vec_length=structfun(@(x) length(x), DataStruct);
                    [~,sort_ind]=sort(vec_length,'descend');
                    vec_names=fields(sort_ind(1:2));

                    %Now we do some basic conditioning of these vectors:
                    %Make column vectors and remove NaNs.
                    vec{1}=DataStruct.(vec_names{1})(:);
                    vec{2}=DataStruct.(vec_names{2})(:);
                    
                    %If there is a start and stopindex, cut down the
                    %longest vector to size.
                    if ismember('startIndex',fields) && ...
                            ismember('stopIndex',fields)
                        [~,ind]=max(cellfun(@(x) length(x), vec));
                        vec{ind}=vec{ind}(DataStruct.startIndex:...
                            DataStruct.stopIndex);
                    end
                    
                    nan_ind=isnan(vec{1}) | isnan(vec{2});
                    vec{1}(nan_ind)=[];
                    vec{2}(nan_ind)=[];
                    
                    %We find what x is by looking for a sorted vector
                    ind_x=cellfun(@(x) issorted(x,'monotonic'),vec);
                    
                    this.Trace.x=vec{ind_x};
                    this.Trace.y=vec{~ind_x};
                    
                    if ismember('offsetFrequency',fields)
                       this.Trace.x=this.Trace.x+DataStruct.offsetFrequency; 
                    end
                otherwise
                    error('File type %s is not supported',ext)
            end
        end
        
        function fitAllPeaks(this,varargin)            
            p=inputParser;
            addParameter(p,'FitNames',{'Gorodetsky2000'});
            addParameter(p,'base_dir',pwd);
            addParameter(p,'session_name','placeholder');
            addParameter(p,'filename','placeholder');
            parse(p,varargin{:});
            
            fit_names=p.Results.FitNames;
            
            %We instantiate the MyFit objects used for the fitting
            Fits=struct();
            for i=1:length(fit_names)
                Fits.(fit_names{i})=launchFit(fit_names{i},...
                    'enable_gui',0);
                Fits.(fit_names{i}).base_dir=p.Results.base_dir;
                Fits.(fit_names{i}).session_name=p.Results.session_name;
                Fits.(fit_names{i}).filename=...
                    [p.Results.filename,'_',fit_names{i}];
            end
            
            %We fit the peaks 
            for i=1:length(this.Peaks)
                %First extract the data around the peak
                [x_fit,y_fit]=extractPeak(this,i);
                
                for j=1:length(fit_names)
                    Fits.(fit_names{j}).Data.x=x_fit;
                    Fits.(fit_names{j}).Data.y=y_fit;
                    genInitParams(Fits.(fit_names{j}));
                    fitTrace(Fits.(fit_names{j}));
                    saveParams(Fits.(fit_names{j}),...
                        'save_user_params',false,...
                        'save_gof',true);
                end
            end
            
            fprintf('Finished fitting peaks \n');
        end
        
        function [x_peak,y_peak]=extractPeak(this,peak_no)
            loc=this.Peaks(peak_no).Location;
            w=this.Peaks(peak_no).Width;
            ind=(loc-8*w<this.Trace.x) & (loc+8*w>this.Trace.x);
            x_peak=this.Trace.x(ind)-loc;
            y_peak=this.Trace.y(ind);
        end
        
        function save(this,varargin)
            %Parse inputs for saving
            p=inputParser;
            addParameter(p,'filename','placeholder',@ischar);
            addParameter(p,'save_dir',pwd,@ischar);
            addParameter(p,'overwrite_flag',false);
            addParameter(p,'save_prec',15);
            parse(p,varargin{:});
            
            %Assign shorter names
            filename=p.Results.filename;
            save_dir=p.Results.save_dir;
            overwrite_flag=p.Results.overwrite_flag;
            save_prec=p.Results.save_prec;
            
            %Puts together the full file name
            fullfilename=fullfile([save_dir,filename,'.txt']);
            
            %Creates the file in the given folder
            write_flag=createFile(save_dir,fullfilename,overwrite_flag);
            
            %Returns if the file is not created for some reason 
            if ~write_flag; return; end
            
            col_names={'Value','Location','Width','Prominence'};
            n_columns=length(col_names);
            %Finds appropriate column width
            cw=max([cellfun(@(x) length(x),col_names), save_prec+7]);
            cw_vec=repmat(cw,1,4);
            
            pre_fmt_str=repmat('%%%is\\t',1,n_columns);
            fmt_str=sprintf([pre_fmt_str,'\r\n'],cw_vec);
            
            fileID=fopen(fullfilename,'w');
            fprintf(fileID,fmt_str,col_names{:});
            
            pre_fmt_str_nmb=repmat('%%%i.15e\\t',1,n_columns);
            %Removes the tab at the end
            pre_fmt_str_nmb((end-2):end)=[];
            
            nmb_fmt_str=sprintf([pre_fmt_str_nmb,'\r\n'],cw_vec);

            fprintf(fileID,nmb_fmt_str,...
                [[this.Peaks.Value];[this.Peaks.Location];...
                [this.Peaks.Width];[this.Peaks.Prominence]]);
            fclose(fileID);
        end
        
        function loadPeaks(this,fullfilename)
            assert(ischar(fullfilename),...
                'File name must be a char, currently it is a %s',...
                class(fullfilename));
            if ~exist(fullfilename,'file')
                error('File named ''%s'' does not exist, choose a different file',...
                fullfilename);
            end
            
            LoadStruct=importdata(fullfilename);
            headers=regexp(LoadStruct.textdata{1},'\s*(\w*)\s*','Tokens');
            this.Peaks=struct(headers{1}{1},num2cell(LoadStruct.data(:,1)),...
                headers{2}{1},num2cell(LoadStruct.data(:,2)),...
                headers{3}{1},num2cell(LoadStruct.data(:,3)),...
                headers{4}{1},num2cell(LoadStruct.data(:,4)));
            
        end
        
        function clearPeaks(this)
            this.Peaks=struct('Location',[],'Width',[],'Prominence',[],...
                'Value',[]);
        end
    end
end

        