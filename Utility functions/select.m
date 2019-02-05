% This simple function that selects between true_opt and false_opt 
% based on the logical value of tf is useful for writing single-line 
% callbacks

function result = select(tf, true_opt, false_opt)
    if tf
        result=true_opt;
    else
        result=false_opt;
    end
end

