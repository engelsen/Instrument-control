% This an abstract class used to derive subclasses only one instance of
% which is allowed to exist at a time.
% See https://ch.mathworks.com/matlabcentral/fileexchange/24911-design-pattern-singleton-creational
% for more information.
% Different to the reference above, the class constructor here is public

classdef MySingletone < handle
    
   methods(Abstract, Static)
      this = getInstance();
   end
   
end

