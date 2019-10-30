% This an abstract class used to derive subclasses only one instance of
% which can exist at a time.
% See https://ch.mathworks.com/matlabcentral/fileexchange/24911-design-pattern-singleton-creational
% for more information.

classdef MySingleton < handle
    
   methods (Abstract, Static)
      this = instance();
   end
end

