function p_in=initParamExponential(x,y)

%Method for estimating initial parameters taken from 
%http://www.matrixlab-examples.com/exponential-regression.html
n=length(x);
y2=log(y);
j=sum(x);
k=sum(y2);
l=sum(x.^2);
r2=sum(x .* y2);
p_in(2)=(n * r2 - k * j)/(n * l - j^2);
p_in(1)=exp((k-p_in(2)*j)/n);

if abs(max(y))>abs(min(y))
    p_in(3)=min(y);
else
    p_in(3)=max(y);
end

end