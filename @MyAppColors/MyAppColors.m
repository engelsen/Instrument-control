% Set of colors indended to introduce some uniformity in GUIs

classdef (Abstract) MyAppColors

    methods (Static)
        %% Predefined colors
        % Colors are represented by rgb triplets returned by static methods
        
        function rgb = ok()
            rgb = [0.47, 0.67, 0.19]; % Green
        end
        
        function rgb = warning()
            rgb = [0.93, 0.69, 0.13]; % Orange
        end
        
        function rgb = error()
            rgb = [1,0,0]; % Red
        end
        
        % Labview-style lamp indicator colors
        function rgb = lampOn()
            rgb = [0,1,0]; % Bright green
        end
        
        function rgb = lampOff()
            rgb = [0,0.4,0]; % Dark green
        end
        
        %% Color scheme functions
        
        function f = createColorSchemeFcn(scheme)
            function colorSchemeFcn(Obj)
                MyAppColors.applyScheme(Obj, scheme)
            end
            
            f = @colorSchemeFcn;
        end
        
        % Recolor app according to a new color scheme
        function applyScheme(Obj, scheme)
            persistent init_default ...
                default_main_color default_label_text_color ...
                default_edit_text_color default_edit_field_color ...
                default_axes_label_color
                    
            if ~exist('scheme', 'var')
                scheme = 'default';
            end

            switch lower(scheme)
                case 'dark'
                    main_color = [8, 62, 118]/255; % = [0.031, 0.24, 0.46]
                    label_text_color = [1,1,1];
                    edit_text_color = [0,0,0];
                    edit_field_color = [1,1,1];
                    axes_label_color = [0.9,0.9,1];
                    
                    state_button_bg_color = [240,240,240]/255;
                    state_button_font_color = [0,0,0];
                case 'bright'
                    main_color = [1,1,1];
                    label_text_color = [0.,0,0.];
                    edit_text_color = [0,0,0.];
                    edit_field_color = [1,1,1];
                    axes_label_color = [0,0,0];
                    
                    state_button_bg_color = [1,1,1];
                    state_button_font_color = [0,0,0];
                case 'default'
                    if isempty(init_default)
                        
                        % Create invisible components and read their
                        % colors
                        Uf = uifigure('Visible', false);
                        Ef = uieditfield(Uf);
                        Lbl = uilabel(Uf);
                        Ax = axes(Uf);
                        
                        default_main_color = Uf.Color;
                        default_label_text_color = Lbl.FontColor;
                        default_edit_text_color = Ef.FontColor;
                        default_edit_field_color = Ef.BackgroundColor;
                        default_axes_label_color = Ax.XColor;
                        delete(Uf);
                        
                        init_default = false;
                    end
                    
                    main_color = default_main_color;
                    label_text_color = default_label_text_color;
                    edit_text_color = default_edit_text_color;
                    edit_field_color = default_edit_field_color;
                    axes_label_color = default_axes_label_color;
                otherwise
                    error('Unknown scheme %s', scheme)
            end

            if isa(Obj, 'matlab.apps.AppBase')
                Fig = findFigure(Obj);
                MyAppColors.applyScheme(Fig, scheme);
                return
            end 
            
            if ~isprop(Obj, 'Type')
                return
            end

            switch Obj.Type
                case 'figure'
                    Obj.Color = main_color;
                case 'uitabgroup'
                    % Nothing to do
                case 'uitab'
                    Obj.ForegroundColor = edit_text_color;
                    Obj.BackgroundColor = main_color;
                case 'uibutton'
                    Obj.FontColor = label_text_color;
                    Obj.BackgroundColor = main_color;
                case 'uistatebutton'
                    Obj.FontColor = state_button_font_color;
                    Obj.BackgroundColor = state_button_bg_color;
                case 'uidropdown'
                    Obj.FontColor = label_text_color;
                    Obj.BackgroundColor = main_color;
                case {'uieditfield', 'uispinner', 'uitextarea', 'uilistbox'}
                    Obj.FontColor = edit_text_color;
                    Obj.BackgroundColor = edit_field_color;
                case {'uilabel', 'uicheckbox', 'uiradiobutton'}
                    Obj.FontColor = label_text_color;
                case {'uipanel', 'uibuttongroup'}
                    Obj.ForegroundColor = label_text_color;
                    Obj.BackgroundColor = main_color;
                case 'axes'
                    try
                        
                        % This property is only present in uiaxes
                        Obj.BackgroundColor = main_color;
                    catch
                    end
                    Obj.XColor = axes_label_color;
                    Obj.YColor = axes_label_color;
                    Obj.GridColor = [0.15, 0.15, 0.15];
                    Obj.MinorGridColor = [0.15, 0.15, 0.15];
                case 'uimenu'
                    Obj.ForegroundColor = edit_text_color;
                case 'uicontrol'
                    
                    % The following switch case is for programmatically
                    % created components
                    switch Obj.Style
                        case {'text', 'pushbutton', 'togglebutton'}
                            Obj.ForegroundColor = label_text_color;
                            Obj.BackgroundColor = main_color;
                        case 'popupmenu'
                            Obj.ForegroundColor = edit_text_color;
                            Obj.BackgroundColor = edit_field_color;
                    end
            end

            if isprop(Obj, 'Children')

                % Recolor children
                for i = 1:length(Obj.Children)
                    MyAppColors.applyScheme(Obj.Children(i), scheme);
                end
            end
        end
    end
end

