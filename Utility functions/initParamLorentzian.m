function [p_in,lim_lower,lim_upper]=initParamLorentzian(x,y)
%Assumes form a/((x-c)^2+(b/2)^2)+d

[amp_max,ind_max]=max(y);
[amp_min,ind_min]=min(y);

lim_upper=[Inf,Inf,Inf,Inf];
lim_lower=[-Inf,0,-Inf,-Inf];

if (abs(amp_max)>abs(amp_min) && amp_max>0) || ...
        (abs(amp_max)<abs(amp_min) && (amp_max<0 || (amp_min<0 && amp_max>0)))
    diff=amp_max-amp_min;
    ind_start_peak=find((y-amp_min)>diff(1)/2,1,'first');
    ind_stop_peak=find((y-amp_min)>diff(1)/2,1,'last');
    p_in(2)=x(ind_stop_peak)-x(ind_start_peak);
    p_in(3)=x(ind_max);
    p_in(4)=amp_min;
else
    diff=amp_min-amp_max;
    ind_start_peak=find((y-amp_max)>diff(1)/2,1,'first');
    ind_stop_peak=find((y-amp_max)>diff(1)/2,1,'last');
    p_in(2)=x(ind_stop_peak)-x(ind_start_peak);
    p_in(3)=x(ind_min);
    p_in(4)=amp_max;
    
end

p_in(1)=diff*((p_in(2)/2)^2);

lim_lower(2)=0.01*p_in(2);
lim_upper(2)=100*p_in(2);

end