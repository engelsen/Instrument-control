function fitdata=fitExponential(x,y,p_in)
x=x(:);
y=y(:);
ffun='a*exp(b*x)+c';

%Setting upper and lower limits
[amp_max,ind_max]=max(y);
[amp_min,ind_min]=min(y);

lim_upper=[Inf,Inf,Inf];
lim_lower=-lim_upper;

if abs(amp_max)>abs(amp_min)
    lim_upper(1)=Inf;
    lim_lower(1)=0;
else
    lim_upper(1)=0;
    lim_lower(1)=-Inf;
end

if ind_max>ind_min
    lim_upper(2)=Inf;
    lim_lower(2)=0;
else
    lim_upper(2)=0;
    lim_lower(2)=-Inf;
end

fitdata=fit(x,y,ffun,'Lower',lim_lower,'Upper',lim_upper,'StartPoint',p_in);
end