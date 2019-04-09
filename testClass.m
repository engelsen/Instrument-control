classdef testClass < MyInstrument & MyCommCont
    
    properties
        Listeners
        PropList
    end
    
    properties (GetAccess = public, SetAccess=public, SetObservable=true)
        prop1 = 1
    end
    
    properties (GetAccess = public, SetAccess=immutable)
        prop2 =0
    end
    
    properties (GetAccess = public, SetAccess=public)
        prop3
    end
    
    methods (Access = public)
        function this = testClass(varargin)
            P = MyClassParser(this);
            processInputs(P, this, varargin{:});
        end
        
        function delete(this)
            try
                delete(this.prop1);
            catch
            end
        end
        
        function preSetCallback(this)
            %isequal(this.prop1, 2);
            
            %disp('Pre Set');
            %disp(this.prop1);
        end
        
        function postSetCallback(this)
            %isequal(this.prop1, 2);
            %disp('Post Set');
            %disp(this.prop1);
        end
    end
    
    methods (Access = protected)
        function createCommandList(this)
            addCommand(this, 'cmd1', ...
                'readFcn', @()rand());
            
            addCommand(this, 'cmd2', ...
                'readFcn', @()rand(), ...
                'writeFcn', @(x)(disp('write cmd2')));
            
            addprop(this,'dynprop1');
            
            mp=addprop(this,'ddp');
            %mp.Dependent = true;
            %mp.GetMethod = @get_ddp;
            mp.SetMethod = @set_ddp;
            this.PropList.ddp.value=1;
        end
        
        function set_ddp(this, val)
            this.ddp = val;
            %this.PropList.ddp.value = val;
        end
        
        function val = get_ddp(this)
            val = this.PropList.ddp.value;
        end
    end
    
    methods
        function set.prop1(this, val)
            if ~isequal(val, this.prop1)
                this.prop1 = val;
                disp('Set method');
            end
        end
    end
end

