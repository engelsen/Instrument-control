function setVisible( varargin )
%setVisible  Show or hide object and its contents
%
%  uix.setVisible(o,v) sets the visibility of the object o to the value v.
%
%  uix.setVisible(o,v,t) sets the visibility asynchronously, at a time t
%  seconds in the future.  The value v may be a literal, or a function
%  handle evaluating to a suitable literal.  Asynchronous mode should only
%  be used to work around bugs, e.g., G1136196 in R2014b.

%  Copyright 2009-2024 The MathWorks, Inc.

switch nargin
    case 2
        setVisibleSync( varargin{:} )
    case 3
        setVisibleAsync( varargin{:} )
    otherwise
        narginchk( 2, 3 )
end

end % setVisible

function setVisibleSync( obj, value )
%setVisibleSync  Show or hide object and its contents
%
%  setVisibleSync(o,'on') shows the object o and its contents.
%
%  setVisibleSync(o,'off') hides the object o and its contents.
%
%  See also: setVisibleAsync

% Imitate matlab.lang.OnOffSwitchState
if isequal( value, true )
    value = 'on';
elseif isequal( value, false )
    value = 'off';
else
    value = char( value );
end

% Set Visible and, if relevant, ContentsVisible
set( obj, 'Visible', value );
if isprop( obj, 'ContentsVisible' )
    set( obj, 'ContentsVisible', value );
end

% As a remedy for G1100294, move off-screen too
if strcmp( value, 'off' )
    margin = 1000;
    for ii = 1:numel( obj )
        if isprop( obj(ii), 'ActivePositionProperty' ) && ...
                strcmp( obj(ii).ActivePositionProperty, 'outerposition' )
            obj(ii).OuterPosition(1) = -obj(ii).OuterPosition(3)-margin;
        else
            obj(ii).Position(1) = -obj(ii).Position(3)-margin;
        end
    end
end

end % setVisibleSync

function setVisibleAsync( obj, f, t )
%setVisibleAsync  Show or hide object, asynchronously
%
%  setVisibleAsync(o,v,t) sets the visibility of the object o to the value
%  v at a time t seconds in the future.  The value can be a literal ('on'
%  or 'off'), or a function handle evaluating to such a literal.
%
%  See also: setVisibleSync

timer = internal.IntervalTimer( t ); % create timer
addlistener( timer, 'Executing', @onTimerExecuting ); % connect
if isprop( obj, 'SetVisibleAsyncTimer') % already participating
    stop( obj.SetVisibleAsyncTimer ) % stop and replace
else
    p = addprop( obj, 'SetVisibleAsyncTimer' ); % create property
    p.Hidden = true; p.Transient = true; % hide property
end
obj.SetVisibleAsyncTimer = timer; % store timer
start( timer ) % start timer

    function onTimerExecuting( ~, ~ )
        stop( timer ) % single shot
        try
            setVisibleSync( obj, f() ) % evaluate and call
        catch e
            warning( e.identifier, '%s', e.message ) % error to warning
        end
        delete( findprop( obj, 'SetVisibleAsyncTimer' ) ) % clean up
    end % onTimerExecuting

end % setVisibleAsync