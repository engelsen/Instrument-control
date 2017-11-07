classdef MyBeta < handle
    properties
        name;
        %Struct containing GUI handles
        Gui;
        %Input parser
        Parser;
        %Trace
        Data
        
        beta;
    end
    
    methods
        function this=MyBeta(varargin)
            createParser(this);
            parse(this.Parser,varargin{:});
            this.Data=this.Parser.Results.Data;
            this.Gui=guihandles(eval('GuiBeta'));
        end
        
        function createParser(this)
            p=inputParser;
            addParameter(p,'Data',MyTrace())
            this.Parser=p;
        end
        
        function calcBeta(this)
            %Number of poist next to peak we will use to find the area
            %under each peak
            n=10;
            % Finding the index of the the centeral maximum and the side bands
            min_pk_dist=200;      
            [peaks,pk_inds] = findpeaks(this.Data.y,...
                'minpeakdistance',min_pk_dist);
            %First we sort by height of the peaks
            amp_sort=sortrows([peaks, pk_inds]);
            %Then we sort the five highest peaks by location
            sort_mat=sortrows(amp_sort((end-4):end,:),2);
            %The sorted indices of the peaks
            ind_sort=sort_mat(:,2);
            
            % Finds indices for the data in the neighborhood of each peak
            %Peak 1 is the leftmost (2nd order peak), Peak 2 is the left
            %1st order peak, Peak 3 is the central peak etc.
            ind_pks=cell(5,1);
            for i=1:5
                ind_pks{i}=(ind_sort(i)-n):(ind_sort(i)+n);
            end
            
            %Here we integrate the data surrounding the peaks and take the
            %square root of the areas. 
            v_rms_pks=cellfun(@(x) sqrt(integrate(this.Data,x)),ind_pks);

            
            % Then we can calculate the FM beta by using: 
            sdratio_01 = 0.5*(v_rms_pks(4)+v_rms_pks(2))/v_rms_pks(3);
            sdratio_02 = 0.5*(v_rms_pks(5)+v_rms_pks(1))/v_rms_pks(3);
            
            syms b;
            %Then find the beta by numerically solution of the bessel
            %functions
            beta_01 = double(vpasolve(besselj(1,b) == ...
                sdratio_01 * besselj(0,b), b, 2*sdratio_01));
            beta_02 = double(vpasolve(besselj(2,b) == ...
                sdratio_02 * besselj(0,b), b, 2*sdratio_02));
            
            %Sets the values on the GUI
            set(this.Gui.Beta02,'String',num2str(beta_02,5));
            set(this.Gui.Beta01,'String',num2str(beta_01,5));
        end
    end
end
