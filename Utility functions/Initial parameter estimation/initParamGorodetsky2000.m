function [p_in,lim_lower,lim_upper]=initParamGorodetsky2000(x,y)
%             { 'a','b','c','d', 'gamma','k0', 'kex'},...
lim_upper=[Inf,Inf,Inf,Inf,Inf];
lim_lower=[-Inf,-Inf,-Inf,-Inf,-Inf];


%Finds peaks on the negative signal (max 2 peaks)
[~,locs,widths,proms]=findpeaks(-y,x,...
    'MinPeakDistance',0.001*range(x),'SortStr','descend','NPeaks',2);


p_in(1)=max(y);

%position
p_in(2)=mean(locs);

if length(locs)==2
    p_in(3)=abs(diff(locs))/2;
else
    p_in(3)=0;
end

p_in(4)=mean(widths)/4;
%Assume critical coupling
p_in(5)=p_in(4);

end