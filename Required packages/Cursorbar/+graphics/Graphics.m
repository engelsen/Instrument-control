classdef (Abstract) Graphics < handle & matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
	% Graphics   Common base class for graphics objects
	%
	% The graphics.Graphics class is the base class of all graphics objects.
	% Because graphics objects are part of a heterogeneous hierarchy, you
	% can create arrays of mixed classes (for example, an array can contain
	% lines, surfaces, axes, and other graphics objects).
	%
   % The class of an array of mixed objects is graphics.Graphics because
   % this class is common to all graphics objects. 
	%
	% Graphics requires the new MATLAB graphics system that
	% was introduced in R2014b
	%
	% Inherited <a href="matlab:help matlab.mixin.CustomDisplay">matlab.mixin.CustomDisplay</a> Methods:
	%    details                 - Fully detailed formal object display.
	%    disp                    - Simple informal object display.
	%    display                 - Print variable name and display object.
	%
	% Inherited <a href="matlab:help matlab.mixin.Heterogeneous">matlab.mixin.Heterogeneous</a> Methods:
	%    cat                     - Concatenation for heterogeneous arrays.
	%    horzcat                 - Horizontal concatenation for
	%                              heterogeneous arrays.
	%    vertcat                 - Vertical concatenation for
	%                              heterogeneous arrays.
	%
	% Protected Methods:
	%    getDefaultScalarElement - Define default element for array
	%                              operations.
	%
	% Inherited <a href="matlab:help handle">handle</a> Methods:
	%    addlistener             - Add listener for event.
	%    delete                  - Delete a handle object.
	%    eq                      - Test handle equality.
	%    findobj                 - Find objects with specified property
	%                              values.
	%    findprop                - Find property of MATLAB handle object.
	%    ge                      - Greater than or equal relation.
	%    gt                      - Greater than relation.
	%    isvalid                 - Test handle validity.
	%    le                      - Less than or equal relation for handles.
	%    lt                      - Less than relation for handles.
	%    ne                      - Not equal relation for handles.
	%    notify                  - Notify listeners of event.
	%
	% Inherited <a href="matlab:help handle">handle</a> Events:
	%    ObjectBeingDestroyed    - Notifies listeners that a particular
	%                              object has been destroyed.
	% Web:
	%    <a href="http://undocumentedmatlab.com/blog/undocumented-cursorbar-object">Undocumented Matlab: Undocumented cursorbar object</a>.
	%
	% See also: graphics.GraphicsPlaceholder, graphics.Cursorbar.
	%
	% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for
	% MATLAB Graphics and for his contribution of new functionality.
	
	% Copyright 2016 The MathWorks, Inc.
	
	%% Main methods
	
	methods
		function hThis = Graphics()
			% Graphics  A Graphics constructor.
			%
			% See also: Graphics.
			
			% Check MATLAB Graphics system version
			if verLessThan('matlab','8.4.0')
				error('graphics:Graphics:Graphics:oldVersion', ...
					'Graphics requires the new MATLAB graphics system that was introduced in R2014b.');
			end
		end
	end
	
	%% Heterogeneous methods
	
	methods (Static, Sealed, Access = protected)
		function defaultObject = getDefaultScalarElement
			defaultObject = graphics.GraphicsPlaceholder;
		end
	end
	
	%% Custom Display Methods
	
	methods (Access = protected, Sealed)
		
		% --------------------------------------
		function header = getHeader(hThis)
			if ~isscalar(hThis)
				% Non-scalar case: call superclass method
				headerStr = getHeader@matlab.mixin.CustomDisplay(hThis);
				if ismatrix(hThis) && ~isempty(hThis)
					header = regexprep(headerStr,' with( no)? properties[\.:]',':');
				else
					header = regexprep(headerStr,' with( no)? properties[\.:]','.');
				end
				header = regexprep(header,'<a.*>heterogeneous</a> |heterogeneous ','');
			else
				% Scalar case: check if a new header is required
				if isprop(hThis,'Tag')
					tagStr = hThis.Tag;
				else
					tagStr = '';
				end
				%
				if isempty(tagStr)
					% No tag: call superclass method
					header = getHeader@matlab.mixin.CustomDisplay(hThis);
				else
					% Use the tag
					headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(hThis);
					header = sprintf('  %s (%s) with properties:\n',headerStr,tagStr);
				end
			end
		end
		
		% --------------------------------------
		function groups = getPropertyGroups(hThis)
			% GETPROPERTYGROUPS  Construct array of property groups.
			if isscalar(hThis)
				% Scalar case: call unsealed getScalarPropertyGroups
				groups = getScalarPropertyGroups(hThis);
			else
				% Non-scalar case: empty list
				groups = matlab.mixin.util.PropertyGroup({});
			end
		end
		
		% --------------------------------------
		function footer = getFooter(hThis)
			% GETFOOTER Build and return display footer text.

			if isscalar(hThis)
				% Scalar case: prompt to show all properties
				%              similarly to graphics objects
				if isempty(properties(hThis))
					% No properties: call superclass method
					footer = getFooter@matlab.mixin.CustomDisplay(hThis);
					return;
				end
				%
				iname = inputname(1);
				if isempty(iname)
					iname = 'ans'; % ans is the default input name
				end
				%
				footer = sprintf(...
					['  Show <a href="matlab: ' ...
					'if exist(''%s'',''var''),' ...
					' matlab.graphics.internal.getForDisplay(''%s'',%s,''%s''), ' ...
					'else,' ...
					' matlab.graphics.internal.getForDisplay(''%s''), ' ...
					'end' ...
					'">all properties</a>\n'], ...
					iname,iname,iname,class(hThis),iname);
			elseif ismatrix(hThis) && ~isempty(hThis)
				% Non-scalar matrix case: show object's classes
				% extract naked class name
				txt = arrayfun(@class,hThis,'Uni',0);
				txt = regexprep(txt,'^.*\.','');
				% add spaces and end-of-line
				len = max(cellfun(@length,txt(:)));
				txt = cellfun(@(s)sprintf('    %-*s',len,s),txt,'Uni',0);
				txt(:,end) = strcat(txt(:,end),{sprintf('\n')});
				% finalize
				footer = cell2mat(txt)';
			else
				% Non-scalar case: call superclass method
				footer = getFooter@matlab.mixin.CustomDisplay(hThis);
			end
		end
	end	
	
	% ============================================================= %
	
	methods (Access = protected)
		function groups = getScalarPropertyGroups(hThis)  %#ok<MANU>
			% GETSCALARPROPERTYGROUPS  Construct array of property groups for display of scalar case.
			
			% default is empty
			groups = matlab.mixin.util.PropertyGroup({});
		end
		
	end
	
end

