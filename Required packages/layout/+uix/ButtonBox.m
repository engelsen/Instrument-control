classdef ButtonBox < uix.Box
    %uix.ButtonBox  Button box base class
    %
    %  uix.ButtonBox is a base class for containers that lay out buttons.
    
    %  Copyright 2009-2020 The MathWorks, Inc.
    
    properties( Access = public, Dependent, AbortSet )
        ButtonSize % button size, in pixels
        HorizontalAlignment % horizontal alignment [left|center|right]
        VerticalAlignment % vertical alignment [top|middle|bottom]
    end
    
    properties( Access = protected )
        ButtonSize_ = [60 20] % backing for ButtonSize
        HorizontalAlignment_ = 'center' % backing for HorizontalAlignment
        VerticalAlignment_ = 'middle' % backing for VerticalAlignment
    end
    
    methods
        
        function value = get.ButtonSize( obj )
            
            value = obj.ButtonSize_;
            
        end % get.ButtonSize
        
        function set.ButtonSize( obj, value )
            
            % Check
            assert( isa( value, 'double' ), 'uix:InvalidPropertyValue', ...
                'Property ''ButtonSize'' must be of type double.' )
            assert( isequal( size( value ), [1 2] ), ...
                'uix:InvalidPropertyValue', ...
                'Size of property ''ButtonSize'' must be 1-by-2.' )
            assert( all( isreal( value ) ) && ~any( isinf( value ) ) && ...
                ~any( isnan( value ) ) && ~any( value <= 0 ), ...
                'uix:InvalidPropertyValue', ...
                'Elements of property ''ButtonSize'' must be real, finite and positive.' )
            
            % Set
            obj.ButtonSize_ = value;
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.ButtonSize
        
        function value = get.HorizontalAlignment( obj )
            
            value = obj.HorizontalAlignment_;
            
        end % get.HorizontalAlignment
        
        function set.HorizontalAlignment( obj, value )
            
            % Check
            try
                assert( ismember( value, {'left';'center';'right'} ) )
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''HorizontalAlignment'' must be ''left'', ''center'' or ''right''.' )
            end % try/catch
            
            % Set
            obj.HorizontalAlignment_ = char( value );
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.HorizontalAlignment
        
        function value = get.VerticalAlignment( obj )
            
            value = obj.VerticalAlignment_;
            
        end % get.VerticalAlignment
        
        function set.VerticalAlignment( obj, value )
            
            % Check
            try
                assert( ismember( value, {'top';'middle';'bottom'} ) )
            catch
                error( 'uix:InvalidPropertyValue', ...
                    'Property ''VerticalAlignment'' must be ''top'', ''middle'' or ''bottom''.' )
            end % try/catch
            
            % Set
            obj.VerticalAlignment_ = char( value );
            
            % Mark as dirty
            obj.Dirty = true;
            
        end % set.VerticalAlignment
        
    end % accessors
    
end % classdef