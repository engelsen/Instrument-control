% the inverse function to xyFourier

function [x_vect, y_vect] = xyInvFourier(freq_vect, sp_vect)
    assert(length(freq_vect)==length(sp_vect), ...
        'lengths of frequency and spectrum vectors should match')
    % We lease the check of the fact that the elements freq_vect are 
    % equally spaced to the user for the sake of time saving
    
    % Make output column if the supplied frequency vector is column
    iscol=iscolumn(freq_vect); 
    
    n=length(freq_vect);
    dx=1/(freq_vect(end)-freq_vect(1)); % step size in x domain
    x_vect=(1:n)*dx;
    
    if iscol
        x_vect=x_vect(:);
    end
    
    n_os=floor(n/2); % Maximum positive frequency index
    
    % Convert the spectrum vercot to column and reshape
    sp_vect=sp_vect(:);
    sp_vect=[sp_vect(end-n_os:end);sp_vect(1:end-n_os-1)];

    y_vect=sqrt(n/dx)*ifft(sp_vect);
    
    if ~iscol
        y_vect=transpose(y_vect);
    end
end

