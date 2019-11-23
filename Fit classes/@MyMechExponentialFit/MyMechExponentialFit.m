% Exponential fit with user parameters defined for convenient
% characterization of mechanical resonators

classdef MyMechExponentialFit < MyExponentialFit
    
    methods (Access = protected)
        function createUserParamList(this)
            addUserParam(this, 'tau', 'title', '\tau (s)', ...
                'editable', 'off')
            addUserParam(this, 'lw', 'title', 'Linewidth (Hz)', ...
                'editable', 'off');
            
            % Frequency at must be inputed by user
            addUserParam(this, 'freq', 'title', 'Frequency (MHz)', ...
                'editable', 'on', 'default', 1)
            addUserParam(this, 'Q', 'title', 'Quality Factor (x10^6)', ...
                'editable', 'off');
            addUserParam(this, 'Qf', 'title', 'Q\times f (10^{14} Hz)', ...
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