struct PendingInvocation
    type::CLRObject
    target::CLRObject
    name::Union{Symbol,Nothing}
end

struct GenericModifier{S}
    subject::S
    params
end

function Base.getindex(pi::PendingInvocation, params...)
    GenericModifier(pi, params)
end

function (call::PendingInvocation)(args...)
    try
        if !isnothing(call.name)
            invokemember(call.type, call.target, call.name, args...)
        else
            invokemember(BindingFlags.CreateInstance, call.type, CLRObject(0), "", args...)
        end
    catch ex
        if ex isa CLRException && isclrtype(ex.object, T"System.Reflection.AmbiguousMatchException")
            rethrow(ErrorException("""Multiple overloads match the given binding criteria.
            Use '$(call.name)[T]()' to call a generic method with a type argument T."""))
        end
        rethrow()
    end
end

function (gencall::GenericModifier{PendingInvocation})(args...)
    type = gencall.subject.type
    name = gencall.subject.name
    ngenarg = length(gencall.params)
    if isnothing(name)
        genty = makegenerictype(type, gencall.params...)
        return invokemember(BindingFlags.CreateInstance, genty, CLRObject(0), "", args...)
    end
    candidates = getmember(type, name)
    for m in candidates
        genargs = invokemember(m, :GetGenericArguments)
        len = invokemember(genargs, :Length)
        if len == ngenarg
            resolved = if ngenarg != 0
                makegenericmethod(m, gencall.params...)
            else
                m
            end
            arr = arrayof(T"System.Object", length(args))
            for (i, x) in enumerate(args)
                arraystore(arr, i - 1, x)
            end
            return invokemember(resolved, :Invoke, gencall.subject.target, arr)
        end
    end
    error("No method named '$name' that takes $ngenarg generic arguments in type $type")
end

function Base.getproperty(obj::CLRObject, sym::Symbol)
    ty = clrtypeof(obj)
    members = nothing
    pi = nothing
    if isassignable(T"System.Type", ty)
        if sym == :new
            return PendingInvocation(obj, CLRObject(0), nothing)
        end
        members = getmember(obj, sym)
        if isempty(members)
            members = getmember(ty, sym)
            if isempty(members)
                error("No such member '$sym' in type $obj")
            end
            pi = PendingInvocation(ty, obj, sym)
            
        else
            pi = PendingInvocation(obj, CLRObject(0), sym)
        end
    else
        members = getmember(ty, sym)
        if isempty(members)
            error("No such member '$sym' in type $ty")
        end
        pi = PendingInvocation(ty, obj, sym)
    end
    return if any(x->isassignable(T"System.Reflection.MethodInfo", clrtypeof(x)), members)
        pi
    else
        invokemember(pi.type, pi.target, pi.name)
    end
end

function Base.setproperty!(obj::CLRObject, sym::Symbol, val)
    ty = clrtypeof(obj)
    flags = BindingFlags.Static | BindingFlags.Instance | BindingFlags.Public | BindingFlags.SetProperty | BindingFlags.SetField
    if isassignable(T"System.Type", ty)
        invokemember(flags, obj, CLRObject(0), sym, val)
    else
        invokemember(flags, ty, obj, sym, val)
    end
end
