function fitdata=fitExponential(x,y)
x=x(:);
y=y(:);
ffun='a*exp(b*x)+c';

%Method for estimating initial parameters taken from 
%http://www.matrixlab-examples.com/exponential-regression.html
n=length(x);
y2=log(y);
j=sum(x);
k=sum(y2);
l=sum(x.^2);
m=sum(y2.^2);
r2=sum(x .* y2);
p_in(2)=(n * r2 - k * j)/(n * l - j^2);
p_in(1)=exp((k-p_in(2)*j)/n);

%Setting upper and lower limits
[amp_max,ind_max]=max(y);
[amp_min,ind_min]=min(y);

lim_upper=[Inf,Inf,Inf];
lim_lower=-lim_upper;

if abs(amp_max)>abs(amp_min)
    lim_upper(1)=Inf;
    lim_lower(1)=0;
    p_in(3)=amp_min;
else
    lim_upper(1)=0;
    lim_lower(1)=-Inf;
    p_in(3)=amp_max;
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