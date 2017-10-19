function [p_in,lim_lower,lim_upper]=initParamGaussian(x,y)
%Assumes a*exp(-((x-c)/b)^2/2)+d - remember matlab orders the fit
%parameters alphabetically

[amp_max,ind_max]=max(y);
[amp_min,ind_min]=min(y);

lim_upper=[Inf,Inf,Inf,Inf];
lim_lower=-lim_upper;

if abs(amp_max)>abs(amp_min)
    amp=amp_max;
    center=x(ind_max);
    lim_upper(1)=Inf;
    lim_lower(1)=0;
else
    amp=amp_min;
    center=x(ind_min);
    lim_upper(1)=0;
    lim_lower(1)=-Inf;
end

width=sqrt(sum(y.*(x-center).^2)/sum(y));
bg=median(y);

%Sets the lower limit on width to zero
lim_lower(2)=0;

%Sets the upper limit on width to 100 times the range of the data
lim_upper(2)=100*range(x);

%Sets upper and lower limit on the center
lim_lower(3)=min(x)/2;
lim_upper(3)=max(x)*2;

p_in=[amp_max,width,center, bg];

end