function Base.show(io::IO, x::CLRObject)
    h = gethandle(x)
    if h == 0
        print(io, "null")
        return
    end
    type = clrtypeof(x)
    if isassignable(Type"System.Type", type)
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
    invokemember(mi, :MakeGenericMethod, args...)
end

function getmember(type::CLRObject, name)
    ret = invokemember(type, :GetMember, typeof(name) == Symbol ? string(name) : name)
    collect(ret)
end

function getmethod(type::CLRObject, name, argtypes...)
    arr = arrayof(Type"System.Type", length(argtypes))
    for (i, t) in enumerate(argtypes)
        arraystore(arr, i - 1, t)
    end
    invokemember(type, :GetMethod, name, arr)
end
