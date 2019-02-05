% Perform physicist's fourier transform of the set of data points (x,y),   
% where the values of x are uniformly spaced, and return the two-sided 
% spectrum. The returned frequency vector is in linear (not angular) units, 
% freq=omega/2p*i

function [freq_vect, sp_vect] = xyFourier(x_vect, y_vect)
    assert(length(x_vect)==length(y_vect), ...
        'lengths of x and y vectors should match')
    % We lease the check of the fact that the elements x_vect are equally
    % spaced to the user for the sake of time saving
    
    % Make output column if the supplied x vector is column
    iscol=iscolumn(x_vect); 
    
    lx=x_vect(end)-x_vect(1); % Interval length 
    n=length(x_vect);
    dx=lx/(n-1); % Step size
    
    n_os=floor(n/2); % Maximum positive frequency index
    
    freq_vect=1/lx*((-(n-1)+n_os):n_os);
    if iscol
        freq_vect=freq_vect(:);
    end
    
    sp_vect=sqrt(dx/n)*fft(y_vect(:));
    sp_vect=[sp_vect(n_os+2:end);sp_vect(1:n_os+1)];
    if ~iscol
        sp_vect=transpose(sp_vect);
    end
end

