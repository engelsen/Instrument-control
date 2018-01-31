classdef (ConstructOnLoad=true) GraphicsPlaceholder < graphics.Graphics
	% GraphicsPlaceholder   Default graphics object.
	%
	% The graphics.GraphicsPlaceholder class defines the default graphics
	% object. Instances of this class appear as: 
	%
	%  *  Elements of pre-allocated arrays created with hobjects.
	%  *  Unassigned array element placeholders
	%  *  Graphics object properties that hold object handles, but are set
	%     to empty values 
	%  *  Empty values returned by functions that return object handles (for
	%     example, findobj). 
	%
	% Usage:
	%    graphics.GraphicsPlaceholder()  - Creates a GraphicsPlaceholder.
	%
	% Example:
	%    x  = linspace(0,20,101);
	%    y  = sin(x);
	%    %
	%    hPlot     = plot(x,y);
	%    hCBar(3)  = cursorbar(hPlot);
	%    hGPHolder = hCBar(1)
	%
	% GraphicsPlaceholder Constructor:
	%    GraphicsPlaceholder    - GraphicsPlaceholder constructor.
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
	% See also: graphics.Graphics, hobjects.
	%
	% Thanks to <a href="http://www.mathworks.com/matlabcentral/profile/authors/3354683-yaroslav">Yaroslav Don</a> for his assistance in updating cursorbar for
	% MATLAB Graphics and for his contribution of new functionality.
	
	% Copyright 2016 The MathWorks, Inc.
	
	%% Main methods
	
	methods
		function hThis = GraphicsPlaceholder()
			% GRAPHICSPLACEHOLDER  A GraphicsPlaceholder constructor.
			%
			% See also: GraphicsPlaceholder.
			
			% Check MATLAB Graphics system version
			if verLessThan('matlab','8.4.0')
				error('graphics:GraphicsPlaceholder:GraphicsPlaceholder:oldVersion', ...
					'GraphicsPlaceholder requires the new MATLAB graphics system that was introduced in R2014b.');
			end
		end
	end
		
end

