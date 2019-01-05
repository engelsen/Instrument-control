classdef MySingleSub < MySingletone
    
    methods(Access=private)
      % Guard the constructor against external invocation.  We only want
      % to allow a single instance of this class.  See description in
      % Singleton superclass.
      function this = MySingleSub()
      end
   end
   
   methods(Static)
      % Concrete implementation.  See Singleton superclass.
      function this = getInstance()
         persistent UniqueInstance
         
         if isempty(UniqueInstance)||(~isvalid(UniqueInstance))
            this = MySingleSub();
            UniqueInstance = this;
            disp('creating new')
         else
            this = UniqueInstance;
            disp('returning existing')
         end
      end
   end
end

