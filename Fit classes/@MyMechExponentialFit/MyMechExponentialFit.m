% Exponential fit with user parameters defined for convenient
% characterization of mechanical resonators

classdef MyMechExponentialFit < MyExponentialFit
    
    methods (Access = protected)
        function createUserParamList(this)
            addUserParam(this, 'tau', 'title', 'τ (s)', ...
                'editable', 'off')
            addUserParam(this, 'lw', 'title', 'Linewidth (Hz)', ...
                'editable', 'off');

            % Frequency must be inputed by user
            addUserParam(this, 'freq', 'title', 'Frequency (MHz)', ...
                'editable', 'on', 'default', 1)
            addUserParam(this, 'Q', 'title', 'Quality factor (×10⁶)', ...
                'editable', 'off');
            addUserParam(this, 'Qf', 'title', 'Q×f (10¹⁴ Hz)', ...
                'editable', 'off');
        end
        
        %Function for calculating the parameters shown in the user panel
        function calcUserParams(this)
            this.tau=abs(1/this.param_vals(2)); 
            this.lw=abs(this.param_vals(2)/pi); 
            this.Q=pi*this.freq*this.tau; 
            this.Qf=this.Q*this.freq/1e2; 
        end
    end
end