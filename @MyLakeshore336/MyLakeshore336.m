% Class communication with Lakeshore Model 336 temperature controller. 
% Tested with DPO4034, DPO3034
classdef MyLakeshore336 < MyInstrument
    
    properties
        Property1
    end
    
    methods (Access=private)
        function this=MyLakeshore336(interface, address, varargin)
            this@MyInstrument(interface, address, varargin{:});
            
            createCommandList(this);
            createCommandParser(this);
            connectDevice(this, interface, address);
        end

        function createCommandList(this)
            % channel from which the data is transferred
            addCommand(this,'channel','DATa:SOUrce','default',1,...
                'str_spec','CH%i');
        end
    end
end

