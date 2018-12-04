% Class with single property 'value', which is passed by reference
classdef MyRefVar < handle
	properties
		value
	end
	methods
		function this = MyRefVar(value)
		  this.value = value;
		end
	end
end

