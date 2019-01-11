% Set of colors indended to introduce some uniformity in GUIs

classdef MyAppColors

    % Colors are represented by rgb triplets returned by static methods
    methods (Static)
        
        function rgb=warning()
            % Orange
            rgb=[0.93, 0.69, 0.13];
        end
        
        function rgb=error()
            % Red
            rgb=[1,0,0];
        end
        
        % Labview-style lamp indicator colors
        function rgb=lampOn()
            % Bright green
            rgb=[0,1,0];
        end
        
        function rgb=lampOff()
            % Dark green
            rgb=[0,0.4,0];
        end
        
    end
    
end

