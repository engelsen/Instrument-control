% The class contains methods for interaction with AppDesigner guis
classdef MyAppMechanics < handle
    
    properties (Access = public)
        Instr; % MyInstrument class object
        linkedElementsList = {} % list of Gui control elements 
        % which have counterpart properties
    end
    
    methods (Access = public)
        function this=MyAppMechanics(Instrument)
            this.Instr=Instrument;
        end
        
        function linkControlElement(this, elem, prop_tag, varargin)
            p=inputParser;
            addRequired(p,'elem');
            addRequired(p,'prop_tag',@ischar);
            addParameter(p,'input_presc',1,@isnumeric);
            addParameter(p,'auto_callback',false, @islogical); 
            parse(p,elem,prop_tag,varargin{:});
            
            % The property-control link is established by assigning the tag
            % and adding the control to the list of linked elements
            elem.Tag = prop_tag;
            this.linkedElementsList = [this.linkedElementsList, elem];
            
            % If the auto callback flag is set, assign the default 
            % ValueChangedFcn which passes the field input to the instument 
            if p.Results.auto_callback
                elem.ValueChangedFcn = createCallbackFcn(this,...
                    @(src, event)genericValueChanged(src, event), true);
            end
            
            % If the prescaler is indicated, add it to the element as a new property
            if p.Results.input_presc ~= 1
                if isprop(elem, 'InputPrescaler')
                    warning('The InputPrescaler propety already exists in the control element');
                else
                    addprop(elem,'InputPrescaler');
                end
                elem.InputPrescaler = p.Results.input_presc;
            end
        end
        
        % update all the linked control elements according to their counterpart properties
        function updateGui(this)
            for i=1:length(this.linkedElementsList)
                tmpelem = this.linkedElementsList(i);
                tmpval = this.Instr.(tmpelem.Tag);
                % scale the value if the control element has a prescaler
                if isprop(tmpelem, 'InputPrescaler')
                    tmpval = tmpval*tmpelem.InputPrescaler;
                end
                tmpelem.Value = tmpval;
            end
        end 
        
        function genericValueChanged(this, event)
            val = event.Value;
            % scale the value if the control element has a prescaler
            if isprop(event.Source, 'InputPrescaler')
                val = val/event.Source.InputPrescaler;
            end
            this.Instr.writePropertyHedged(event.Source.Tag, val);
            this.updateGui();
        end
    end
end