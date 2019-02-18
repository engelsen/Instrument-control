classdef MyAppSync < handle
    
    properties (GetAccess=public, SetAccess=private)
        Listeners
        LinkedElements % Array of graphics objects
    end
    
    methods
        
        function this=MyAppSync(varargin)
            % Varargin is a list of objects
            this.Listeners.NewSetting=addlistener(this,'NewSetting', ...
                @(Src, EventData)newSettingCallback(this, Src, EventData));
            this.Listeners.GuiDestroyed=addlistener(Val,'ObjectBeingDestroyed', ...
                @(Src, EventData)guiDeletedCallback(this, Src, EventData));
        end
        
        function delete(this)
            %Deletes listeners
            try
                lnames=fieldnames(this.Listeners);
                for i=1:length(lnames)
                    try
                        delete(this.Listeners.(lnames{i}));
                    catch
                        fprintf(['Could not delete the listener to ' ...
                            '''%s'' event.\n'], lnames{i})
                    end
                end
            catch
            end
        end
        
        function newSettingCallback(this, Src, EventData)
            
        end
    end
end

