% Lorenzian fit with additional user parameters useful for the 
% characterization of mechanical oscillators

classdef MyMechLorentzianFit < MyLorentzianFit
    methods (Access = protected)
        
        %Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            lw = this.param_vals(2); 
            freq = this.param_vals(3); 
            
            this.lw = lw;                % Linewidth in Hz
            this.freq = freq/1e6;        % Frequency in MHz
            this.Q = (freq/lw)/1e6;      % Q in millions  
            this.Qf = (freq^2/lw)/1e14;  % Qf in 10^14 
        end
        
        function createUserParamList(this)
            addUserParam(this, 'lw', 'title', 'Linewidth (Hz)', ...
                'editable', 'off')
            addUserParam(this, 'freq', 'title', 'Frequency (MHz)', ...
                'editable', 'off')
            addUserParam(this, 'Q', 'title', 'Qualify Factor (x10^6)', ...
                'editable', 'off');
            addUserParam(this, 'Qf', 'title', 'Q\times f (10^{14} Hz)', ...
                'editable', 'off');
        end
        
        function createUserGuiStruct(this)
            createUserGuiStruct@MyFit(this);
            
            %Parameters for the tab relating to mechanics
            this.UserGui.Tabs.Mech.tab_title='Mech.';
            this.UserGui.Tabs.Mech.Children={};
            addUserField(this,'Mech','mech_lw','Linewidth (Hz)',1,...
                'enable_flag','off')
            addUserField(this,'Mech','Q',...
                'Qualify Factor (x10^6)',1e6,...
                'enable_flag','off','conv_factor',1e6)
            addUserField(this,'Mech','mech_freq','Frequency (MHz)',1e6,...
                'conv_factor',1e6, 'enable_flag','off')
            addUserField(this,'Mech','Qf','Q\times f (10^{14} Hz)',1e14,...
                'conv_factor',1e14,'enable_flag','off');
            
            %Parameters for the tab relating to optics
            this.UserGui.Tabs.Opt.tab_title='Optical';
            this.UserGui.Tabs.Opt.Children={};
            addUserField(this,'Opt','line_spacing',...
                'Line Spacing (MHz)',1e6,'conv_factor',1e6,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','line_no','Number of lines',1,...
                'Callback', @(~,~) calcUserParams(this));
            addUserField(this,'Opt','opt_lw','Linewidth (MHz)',1e6,...
                'enable_flag','off','conv_factor',1e6);
        end
    end
end

