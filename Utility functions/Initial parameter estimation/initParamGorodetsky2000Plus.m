function [p_in,lim_lower,lim_upper]=initParamGorodetsky2000Plus(x,y)
%             { 'a','b','c', 'gamma','k0', 'kex'},...
lim_upper=[Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf];
lim_lower=[0,-Inf,-Inf,-Inf,-Inf,-Inf,0,0,0];


%Finds peaks on the negative signal (max 2 peaks)
[~,locs,widths,proms]=findpeaks(-y,x,...
    'MinPeakDistance',0.001*range(x),'SortStr','descend','NPeaks',2);




%position
p_in(2)=mean(locs);

% %Extract data outside peak
ind=false(length(x),1);
ind(x<(locs(1)-widths(1)) | x>(locs(1)+widths(1)))=true;
poly_coeffs=polyfit(x(ind),y(ind),3);
 
 
p_in(1)=poly_coeffs(4);
p_in(3)=poly_coeffs(3);
p_in(4)=poly_coeffs(2);
p_in(5)=poly_coeffs(1);

%background
p_in(6)=0;

if length(locs)==2
    p_in(7)=abs(diff(locs))/2;
else
    p_in(7)=0;
end

transmission=min(y)/max(y);
p_in(9) = (widths(1)/2)*(1-sqrt(transmission));
p_in(8) = widths(1)-p_in(9);


end