% Add all the properties of Object which are not present in the 
% scheme of inputParser p and which have public set acces 
% to the scheme of p 
function addClassPropeties(p, Object)
    ObjMetaclass = metaclass(Object);    
    for i=1:length(ObjMetaclass.PropertyList)
        Tmp = ObjMetaclass.PropertyList(i);
        % Constant, Dependent and Abstract propeties cannot be set
        if (~Tmp.Constant)&&(~Tmp.Abstract)&&(~Tmp.Dependent)&&...
                strcmpi(Tmp.SetAccess,'public')&&...
                (~ismember(Tmp.Name, p.Parameters))
            if Tmp.HasDefault
                def = Tmp.DefaultValue;
            else
                def = [];
            end
            addParameter(p, Tmp.Name, def);
        end
    end
end

