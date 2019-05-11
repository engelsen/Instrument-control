% Object for testing data acquisition and header collection functionality

classdef MyDummyScpiInstrument < MyScpiInstrument & MyDataSource
    
    properties (Access = public)
        point_no = 1000
    end
    
    methods (Access = public)
        function this = MyDummyScpiInstrument()
            createCommandList(this);
        end
        
        function readTrace(this)
            
            % Generate a random trace with the length equal to point_no
            this.Trace.x = 1:this.point_no;
            this.Trace.y = rand(1, this.point_no);
            
            triggerNewData(this);
        end
        
        % Replacement method that emulates communication with physical
        % device
        function resp_str = queryString(this, query_str)
            query_cmds = strsplit(query_str, ';');
            
            resp_str = '';
            for i = 1:length(query_cmds)
                cmd = query_cmds{i};
                if ~isempty(cmd)
                    switch cmd
                        case 'COMMAND1'
                            tmp_resp = sprintf(this.CommandList.cmd1.format, ...
                                this.cmd1);
                        case 'COMMAND2'
                            tmp_resp = sprintf(this.CommandList.cmd2.format, ...
                                this.cmd2);
                        case 'COMMAND3'
                            tmp_resp = sprintf(this.CommandList.cmd3.format, ...
                                this.cmd3);
                        otherwise
                            tmp_resp = '';
                    end

                    resp_str = [resp_str ';' tmp_resp]; %#ok<AGROW>
                end
            end
        end
        
        % writeString does nothing
        function writeString(this, str) %#ok<INUSD>
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            
            addCommand(this, 'cmd1', 'COMMAND1', ...
                'format',   '%e', ...
                'info',     'regular read/write numeric command');
            
            addCommand(this, 'cmd2', 'COMMAND2', ...
                'format',   '%s', ...
                'info',     'regular read/write string command', ...
                'default',  'val');
            
            addCommand(this, 'cmd3', 'COMMAND3', ...
                'format',   '%i,%i,%i', ...
                'info',     'read/write vector');
        end
    end
end

