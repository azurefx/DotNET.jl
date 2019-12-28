struct PendingInvocation
    type::CLRObject
    target::CLRObject
    name::Symbol
end

function (call::PendingInvocation)(args...)
    invokemember(call.type, call.target, call.name, args...)
end

function Base.getproperty(obj::CLRObject, sym::Symbol)
    ty = clrtypeof(obj)
    members = nothing
    pi = nothing
    if isassignable(Type"System.Type", ty)
        members = getmember(obj, sym)
        if isempty(members)
            members = getmember(ty, sym)
            if isempty(members)
                error("No such member '$sym' for type $obj")
            end
            pi = PendingInvocation(ty, obj, sym)
            
        else
            pi = PendingInvocation(obj, CLRObject(0), sym)
        end
    else
        members = getmember(ty, sym)
        if isempty(members)
            error("No such member '$sym' for type $ty")
        end
        pi = PendingInvocation(ty, obj, sym)
    end
    return if any(x->isassignable(Type"System.Reflection.MethodInfo", clrtypeof(x)), members)
        pi
    else
        invokemember(pi.type, pi.target, pi.name)
    end
end
