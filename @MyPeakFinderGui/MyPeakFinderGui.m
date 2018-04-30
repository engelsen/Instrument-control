classdef MyPeakFinderGui < handle
    properties
        PeakFinder
        Gui;
        axis_handle;
    end
    
    properties (Access=private)
        peak_color='r';
        data_color='b';
        peak_handle;
    end
    
    properties (Dependent=true)
        trace_handle;
        filename;
        session_name;
        base_dir;
        save_dir;
    end
    
    methods
        function this=MyPeakFinderGui()
            this.PeakFinder=MyPeakFinder();
            createGui(this);
        end
        
        function delete(this)
            %Avoids loops
            set(this.Gui.Window,'CloseRequestFcn','');
            %Deletes the figure
            delete(this.Gui.Window);
            %Removes the figure handle to prevent memory leaks
            this.Gui=[];
        end
        
        function closeFigure(this, ~, ~)
            delete(this);
        end
        
        function analyzeCallback(this, src, ~)
            src.BackgroundColor=[1,0,0];
            src.String='Analyzing..';
            
            searchPeaks(this.PeakFinder,...
                'MinPeakProminence',str2double(this.Gui.PromEdit.String),...
                'MinPeakDistance',str2double(this.Gui.SepEdit.String),...
                'FindMinima',this.Gui.MinimaCheck.Value);
            plotPeaks(this);
            src.BackgroundColor=[0.94,0.94,0.94];
            src.String='Analyze';
        end
        
        function plotPeaks(this)
            delete(this.peak_handle);
            this.peak_handle=plot(this.axis_handle,...
                [this.PeakFinder.Peaks.Location],...
                [this.PeakFinder.Peaks.Value],...
                'Marker','o',...
                'LineStyle','none',...
                'Color',this.peak_color);
        end
        
        function fitPeakCallback(this,~,~)
            fitAllPeaks(this.PeakFinder,...
                'base_dir',this.base_dir,...
                'session_name',this.session_name,...
                'filename',this.filename);
        end
            
        function clickCallback(this,~,~)
            switch this.Gui.Window.SelectionType
                case 'normal'   %Left click
                    addPeak(this);
                case 'alt'      %Right click
                    axis(this.axis_handle,'tight')
                case 'extend'     %Shift click
                    coords=this.axis_handle.CurrentPoint;
                    removePeak(this, coords(1));
                otherwise
            end
        end
        
        function windowScrollCallback(this, ~, event)
            coords=this.axis_handle.CurrentPoint;
            
            if event.VerticalScrollCount>0
                %Zoom out
                zoomAxis(this,coords(1),0.1)
            else
                %Zoom in
                zoomAxis(this,coords(1),10);
            end
        end
        
        function removePeak(this, coord)
            [~,ind]=min(abs([this.PeakFinder.Peaks.Location]-coord));
            this.PeakFinder.Peaks(ind)=[];
            plotPeaks(this);
        end
        
        function addPeak(this)
            x_lim=[this.axis_handle.XLim(1),...
                this.axis_handle.XLim(2)];
            searchPeaks(this.PeakFinder,...
                'ClearPeaks',false,...
                'Limits',x_lim,...
                'MinPeakProminence',str2double(this.Gui.PromEdit.String),...
                'FindMinima',this.Gui.MinimaCheck.Value,...
                'NPeaks',1,...
                'SortStr','descend');
            plotPeaks(this);
        end
        
        function zoomAxis(this,coords,zoom_factor)
            curr_width=this.axis_handle.XLim(2)-this.axis_handle.XLim(1);
            new_width=curr_width/zoom_factor;
            this.axis_handle.XLim=...
                [coords(1)-new_width/2,coords(1)+new_width/2];
        end
        
        function clearCallback(this, ~, ~)
            delete(getLineHandle(this.PeakFinder.Trace,this.axis_handle));
            clearData(this.PeakFinder.Trace);
            cla(this.axis_handle);
        end
        
        function loadTraceCallback(this, src, ~)
            %Window can find all files
            [fname,path]=uigetfile('*.*');
            if fname==0
                warning('No file was selected');
                return
            end
            src.BackgroundColor=[1,0,0];
            src.String='Loading..';
            
            loadTrace(this.PeakFinder,[path,fname]);
            plotTrace(this.PeakFinder.Trace,this.axis_handle);
            this.trace_handle.ButtonDownFcn=...
                @(src, event) clickCallback(this, src, event);
            
            exitLoad(this);
        end
        
        function exitLoad(this)
            this.Gui.LoadTraceButton.BackgroundColor=[0.94,0.94,0.94];
            this.Gui.LoadTraceButton.String='Load trace';
        end
            
        function savePeaksCallback(this,~,~)
            save(this.PeakFinder,...
                'save_dir',this.save_dir,...
                'filename',this.filename);
        end
        
        function loadPeaksCallback(this,~,~)
            [fname,path]=uigetfile('*.*');
            if fname==0
                warning('No file was selected');
                return
            end
            loadPeaks(this.PeakFinder,[path,fname]);
            plotPeaks(this);
        end
        
        function clearPeaksCallback(this,~,~)
            clearPeaks(this.PeakFinder);
            delete(this.peak_handle);
        end
    end
    
    methods
        function trace_handle=get.trace_handle(this)
            trace_handle=getLineHandle(this.PeakFinder.Trace,this.axis_handle);
        end
        
        function base_dir=get.base_dir(this)
            try
                base_dir=this.Gui.BaseEdit.String;
            catch
                base_dir=pwd;
            end
        end
        
        function set.base_dir(this,base_dir)
            this.Gui.BaseEdit.String=base_dir;
        end
        
        function session_name=get.session_name(this)
            try
                session_name=this.Gui.SessionEdit.String;
            catch
                session_name='';
            end
        end
        
        function set.session_name(this,session_name)
            this.Gui.SessionEdit.String=session_name;
        end
        
        function filename=get.filename(this)
            try
                filename=this.Gui.FileNameEdit.String;
            catch
                filename='placeholder';
            end
        end
        
        function set.filename(this,filename)
            this.Gui.FileNameEdit.String=filename;
        end
        
        %Get function from save directory
        function save_dir=get.save_dir(this)
            save_dir=createSessionPath(this.base_dir,this.session_name);
        end
    end
end