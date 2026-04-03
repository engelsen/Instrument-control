function t = figuretype( o )
%figuretype  Figure type
%
%  t = uix.figuretype(o) returns the figure type of the graphics object o:
%  'none' (unrooted), 'java' (up to R2025a), or 'js'.

%  Copyright 2024-2025 The MathWorks, Inc.

f = ancestor( o, 'figure' );
if isempty( f )
    t = 'none';
elseif isprop( f, 'JavaFrame_I' ) && ~isempty( f.JavaFrame_I )
    t = 'java';
else
    t = 'js';
end

end % figuretype