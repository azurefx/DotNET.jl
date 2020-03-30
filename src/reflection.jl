function Base.show(io::IO, x::CLRObject)
    h = gethandle(x)
    if h == 0
        print(io, "null")
        return
    end
    type = clrtypeof(x)
    if isassignable(T"System.Type", type)
        print(io, string(x))
    else 
        print(io, string(type))
        print(io, "(")
        unboxed = unbox(x)
        if typeof(unboxed) == CLRObject
            print(io, repr(string(x)))
        else
            print(io, repr(unboxed))
        end
        print(io, ")")
    end
end

function makegenericmethod(mi::CLRObject, args...)
    invokemember(T"System.Reflection.MethodInfo", mi, :MakeGenericMethod, args...)
end

function makegenerictype(ty::CLRObject, args...)
    invokemember(T"System.Type", ty, :MakeGenericType, args...)
end

function getmember(type::CLRObject, name)
    ret = invokemember(type, :GetMember, typeof(name) == Symbol ? string(name) : name)
    collect(ret)
end

function getmethod(type::CLRObject, name, argtypes...)
    arr = arrayof(T"System.Type", length(argtypes))
    for (i, t) in enumerate(argtypes)
        arraystore(arr, i - 1, t)
    end
    invokemember(type, :GetMethod, name, arr)
end

function getevent(type::CLRObject,name)
    invokemember(type, :GetEvent, typeof(name) == Symbol ? string(name) : name)
end
