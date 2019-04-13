% Class for controlling 4-channel Tektronix DPO scopes. 
% Tested with DPO4034, DPO3034

classdef MyDpo < MyTekScope
    
    methods (Access = public)
        function this = MyDpo(varargin)
            this@MyTekScope(varargin{:});
            
            % 2e7 is the maximum trace size of DPO4034-3034 
            %(10 mln point of 2-byte integers)
            this.Device.InputBufferSize = 2.1e7; %byte 
            
            this.knob_list = lower({'GPKNOB1','GPKNOB2','HORZPos', ...
                'HORZScale, TRIGLevel','PANKNOB1','VERTPOS', ...
                'VERTSCALE','ZOOM'});
        end
    end
end