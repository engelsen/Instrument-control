classdef MyDeviceComm < handle

    properties (Access=public)
        Device %Device communication object    
    end
    
    methods
        function this = MyDeviceComm()
            
        end
        
        function delete(this)         
            %Closes the connection to the device
            closeDevice(this);
            %Deletes the device object
            try
                delete(this.Device);
            catch
            end
        end 
        
    end
end

