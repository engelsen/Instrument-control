classdef( Hidden, Sealed ) SelectionChangedData < event.EventData
    %uix.SelectionChangedData  Event data for selection event
    %
    %  e = uix.SelectionChangedData(o,n) creates event data including the old
    %  value o and the new value n.

    %  Copyright 2009-2024 The MathWorks, Inc.

    properties( SetAccess = private )
        OldValue % old value
        NewValue % newValue
    end

    methods

        function obj = SelectionChangedData( oldValue, newValue )
            %uix.SelectionChangedData  Event data for selection event
            %
            %  e = uix.SelectionChangedData(o,n) creates event data
            %  including the old value o and the new value n.

            % Set properties
            obj.OldValue = oldValue;
            obj.NewValue = newValue;

        end % constructor

    end % structors

end % classdef