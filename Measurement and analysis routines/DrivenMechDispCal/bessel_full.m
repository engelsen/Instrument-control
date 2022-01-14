function y = bessel_full(beta,a,b,n)            
    y = zeros(size(n));            
    for i = 1:size(n)                
        k = n(i);                
        if mod(k,2) == 1
            y(i) = a*(besselj(k,beta)^2);                    
        else
            y(i) = b*(besselj(k,beta)^2);
        end                
    end
end           
        