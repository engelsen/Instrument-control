classdef MyRefVar < handle
% A simple variable, the value of which is passed by reference
	properties
		value
	end
	methods
		function this = MyRefVar(value)
		  this.value = value;
		end
	end
end

