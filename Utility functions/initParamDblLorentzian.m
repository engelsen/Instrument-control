function [p_in,lim_lower,lim_upper]=initParamDblLorentzian(x,y)
%Assumes form a/pi*b/2/((x-c)^2+(b/2)^2)+d/pi*e/2/((x-f)^2+(e/2)^2))+g

lim_upper=[Inf,Inf,Inf,Inf,Inf,Inf,Inf];
lim_lower=[-Inf,0,-Inf,-Inf,0,-Inf,-Inf];

%Finds peaks on the positive signal (max 2 peaks)
[~,locs{1},widths{1},proms{1}]=findpeaks(y,x,...
    'MinPeakDistance',0.01*range(x),'SortStr','descend','NPeaks',2);
%Finds peaks on the negative signal (max 2 peaks)
[~,locs{2},widths{2},proms{2}]=findpeaks(-y,x,...
    'MinPeakDistance',0.001*range(x),'SortStr','descend','NPeaks',2);

if proms{1}(1)>proms{2}(1)
    ind=1;
    lim_lower(1)=0;
    lim_lower(4)=0;
    p_in(7)=min(y);
else
    lim_upper(1)=0;
    lim_upper(4)=0;
    ind=2;
    p_in(7)=max(y);
    proms{2}=-proms{2};
end

p_in(2)=widths{ind}(1);
p_in(1)=proms{ind}(1)*pi*p_in(2)/2;
p_in(3)=locs{ind}(1);
p_in(5)=widths{ind}(2);
p_in(4)=proms{ind}(2)*pi*p_in(5)/2;
p_in(6)=locs{ind}(2);

if abs(p_in(1))>abs(10*p_in(4))
    p_in(1)=p_in(1)/2;
    p_in(5)=p_in(2);
    p_in(6)=p_in(3);
    p_in(4)=p_in(1);
end

lim_lower(2)=0.01*p_in(2);
lim_upper(2)=100*p_in(2);

lim_lower(5)=0.01*p_in(5);
lim_upper(5)=100*p_in(5);
end