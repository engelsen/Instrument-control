function [p_in,lim_lower,lim_upper]=initParamLorentzian(x,y)
%Assumes form a/pi*b/2/((x-c)^2+(b/2)^2)+d

lim_upper=[Inf,Inf,Inf,Inf];
lim_lower=[-Inf,0,-Inf,-Inf];

%Finds peaks on the positive signal (max 1 peak)
[~,locs(1),widths(1),proms(1)]=findpeaks(y,x,...
    'MinPeakDistance',range(x)/2,'SortStr','descend',...
    'NPeaks',1);
%Finds peaks on the negative signal (max 1 peak)
[~,locs(2),widths(2),proms(2)]=findpeaks(-y,x,...
    'MinPeakDistance',range(x)/2,'SortStr','descend',...
    'NPeaks',1);

if proms(1)>proms(2)
    ind=1;
    p_in(4)=min(y);
else
    ind=2;
    p_in(4)=max(y);
    proms(2)=-proms(2);
end

p_in(2)=widths(ind);
p_in(1)=proms(ind)*pi*p_in(2)/2;
p_in(3)=locs(ind);


lim_lower(2)=0.01*p_in(2);
lim_upper(2)=100*p_in(2);

end