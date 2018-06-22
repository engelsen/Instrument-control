function [p_in,lim_lower,lim_upper]=initParamGorodetsky2000Plus(x,y)
%             { 'a','b','c', 'gamma','k0', 'kex'},...
lim_upper=[Inf,Inf,Inf,Inf,Inf,Inf,Inf];
lim_lower=[-Inf,-Inf,-Inf,-Inf,0,0,0];


%Finds peaks on the negative signal (max 2 peaks)
[~,locs,widths,proms]=findpeaks(-y,x,...
    'MinPeakDistance',0.001*range(x),'SortStr','descend','NPeaks',2);


p_in(1)=max(y);

%position
p_in(2)=mean(locs);

p_in(3)=(y(end)-y(1))/(x(end)-x(1));
p_in(4)=0;

if length(locs)==2
    p_in(5)=abs(diff(locs))/2;
else
    p_in(5)=0;
end

p_in(6)=mean(widths)/2;
%Assume critical coupling
p_in(7)=p_in(4);

end