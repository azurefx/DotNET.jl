const TYPE_CACHE = Dict{String,CLRObject}()

function gettypecached(typename)
    if haskey(TYPE_CACHE, typename)
        return TYPE_CACHE[typename]
    end
    ty = CLRBridge.GetType(typename)
    if gethandle(ty) != 0
        TYPE_CACHE[typename] = ty
    end
    return ty
end

macro Type_str(name)
    :(gettypecached($name))
end

function clrtypeof(x::CLRObject)
    CLRBridge.GetObjectType(gethandle(x))
end

function isclrtype(x::CLRObject, t::CLRObject)
    xt = clrtypeof(x)
    ret = CLRBridge.InvokeMember(gethandle(clrtypeof(xt)), "Equals", CLRBridge.BindingFlags.InvokeMethod,
    0, gethandle(xt), [gethandle(t)])
    return CLRBridge.GetBool(gethandle(ret))
end

function isassignable(totype::CLRObject, fromtype::CLRObject)
    ret = CLRBridge.InvokeMember(gethandle(Type"System.Type"), "IsAssignableFrom",
    CLRBridge.BindingFlags.InvokeMethod, 0, gethandle(totype), [gethandle(fromtype)])
    return CLRBridge.GetBool(gethandle(ret))
end
