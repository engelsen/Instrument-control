% Lorenzian fit customized for the characterization of quality factors of
% mechanical resonators

classdef MyMechLorentzianFit < MyLorentzianFit
    methods (Access = protected)
        
        % Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            lw = this.param_vals(2); 
            freq = this.param_vals(3); 
            
            this.lw = lw;                % Linewidth in Hz
            this.freq = freq/1e6;        % Frequency in MHz
            this.Q = (freq/lw)/1e6;      % Q in millions  
            this.Qf = (freq^2/lw)/1e14;  % Qf in 10^14 Hz
        end
        
        function createUserParamList(this)
            addUserParam(this, 'lw', 'title', 'Linewidth (Hz)', ...
                'editable', 'off')
            addUserParam(this, 'freq', 'title', 'Frequency (MHz)', ...
                'editable', 'off')
            addUserParam(this, 'Q', 'title', 'Quality factor (×10<sup>6</sup>)', ...
                'editable', 'off');
            addUserParam(this, 'Qf', 'title', 'Q×f (10<sup>14</sup> Hz)', ...
                'editable', 'off');
        end
    end
end

