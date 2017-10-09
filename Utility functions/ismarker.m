function bool=ismarker(marker)

bool=any(strcmpi({'.','o','x','+','*','s','d','v','^','<','>','p','h',...
    'square','diamond','pentagram','hexagram','none'}, marker));

end