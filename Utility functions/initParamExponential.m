function [p_in,lim_lower,lim_upper]=initParamExponential(x,y)
%Assumes form a*exp(-bx)+c

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

%Method for estimating initial parameters taken from 
%http://www.matrixlab-examples.com/exponential-regression.html. Some
%modifications to account for negative y values

n=length(x);
y2=log(y);
j=sum(x);
k=sum(y2);
l=sum(x.^2);
r2=sum(x .* y2);
p_in(2)=(n * r2 - k * j)/(n * l - j^2);
p_in(1)=exp((k-p_in(2)*j)/n);

if abs(amp_max)>abs(amp_min)
    p_in(3)=min(y);
else
    p_in(3)=max(y);
end

end