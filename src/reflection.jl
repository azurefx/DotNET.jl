function Base.show(io::IO, x::CLRObject)
    h = gethandle(x)
    if h == 0
        print(io, "null")
        return
    end
    type = clrtypeof(x)
    if isassignable(Type"System.Type", type)
        println(io, string(x))
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

function getmethods(type::CLRObject, name)
    collect(invokemember(type, :GetMember, name))
end
