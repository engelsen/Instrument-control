% Class featuring a specialized framework for instruments supporting SCPI 

classdef MyScpiInstrument < MyInstrument
    
    methods (Access = public)
        function this = MyScpiInstrument()
            
        end
        
        % Extend the functionality of base class method
        function addCommand(this, tag, varargin)
            p=inputParser();
            p.KeepUnmatched=true;
            addParameter(p,'command','',@ischar);
            addParameter(p,'access','rw',@ischar);
            parse(p, varargin{:});
            
            % Supply the remaining parameters to the base function
            unmatched_nv=struct2namevalue(p.Unmatched);
            addCommand@MyInstrument(this, tag, unmatched_nv{:});
            
            % Add abbreviated forms to the list of values
            this.CommandList.(tag).val_list = ...
                extendValList(this, this.CommandList.(tag).val_list);
            
            % Create read and write functions
            if ~isempty(p.Results.command)
                
            end
        end
        
        % 
        function sync(this)
           
        end
    end
    
    methods (Access = protected)
        %% Write/query
        % These methods implement handling multiple SCPI commands. Unless 
        % overloaded, for communication with the device they rely on  
        % write/readString methods, which particular subclasses must 
        % implement or inherit separately.
        
        % Write command strings listed in varargin
        function writeCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';');
                cmd_str=cmd_str{1};
                writeString(this, cmd_str);
            end
        end
        
        % Query commands and return the resut as cell array of strings
        function res_list = queryCommand(this, varargin)
            if ~isempty(varargin)
                % Concatenate commands and send to the device
                cmd_str=join(varargin,';');
                cmd_str=cmd_str{1};
                res_str=queryString(this, cmd_str);
                % Drop the end-of-the-string symbol and split
                res_list=split(deblank(res_str),';');
            else
                res_list={};
            end
        end
        
        function scpiWriteFcn(this, tag, val)
        end
        
        function val = scpiReadFcn(this, tag)
        end
        
        %% Misc utility methods
        
        % Add the list of values, if needed extending it to include
        % short forms. For example, for the allowed value 'AVErage'
        % its short form 'AVE' also will be added.
        function ext_vl = extendValList(~, vl)
            short_vl={};
            for i=1:length(vl)
                if ischar(vl{i})
                    idx = isstrprop(vl{i},'upper');
                    short_form=vl{i}(idx);
                    % Add the short form to the list of values if it was
                    % not included explicitly
                    if ~ismember(short_form, vl)
                        short_vl{end+1}=short_form; %#ok<AGROW>
                    end
                end
            end
            ext_vl=[vl, short_vl];
        end
    end
    
end

