classdef Container < matlab.ui.container.internal.UIContainer
    %uix.Container  Container base class
    %
    %  uix.Container is base class for containers that extend uicontainer.

    %  Copyright 2009-2020 The MathWorks, Inc.

    methods( Access = protected, Static )

        function map = getThemeMap()
            %getThemeMap  Map class properties to theme attributes

            map = struct();
            map.BackgroundColor = '--mw-backgroundColor-primary';

        end % getThemeMap

    end % protected static methods

end % classdef