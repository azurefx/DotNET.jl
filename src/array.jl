function iterate_ienumerable(enumerator::CLRObject)
    enumeratorty = T"System.Collections.IEnumerator"
    hasnext = invokemember(enumeratorty, enumerator, :MoveNext)
    hasnext || return nothing
    next = invokemember(enumeratorty, enumerator, :Current)
    return (next, (enumerator, enumeratorty))
end

function iterate_ienumerable_t(enumerator::CLRObject, elt::CLRObject)
    enumeratorty = makegenerictype(T"System.Collections.Generic.IEnumerator`1", elt)
    hasnext = invokemember(enumeratorty, enumerator, :MoveNext)
    hasnext || return nothing
    next = invokemember(enumeratorty, enumerator, :Current)
    return (next, (enumerator, enumeratorty))
end

function Base.iterate(obj::CLRObject)
    isnull(obj) && return nothing
    objty = clrtypeof(obj)
    enumerablety = T"System.Collections.IEnumerable"
    if isassignable(enumerablety, objty)
        enumerator = invokemember(enumerablety, obj, :GetEnumerator)
        return iterate_ienumerable(enumerator)
    end
    elt = clreltype(obj)
    if !isnull(elt)
        enumerablety = makegenerictype(T"System.Collections.Generic.IEnumerable`1", elt)
        if isassignable(enumerablety, objty)
            enumerator = invokemember(enumerablety, obj, :GetEnumerator)
            return iterate_ienumerable(enumerator)
        end
    end
    throw(ArgumentError("Object is not iterable"))
end

function Base.iterate(::CLRObject, state)
    enumerator, enumeratorty = state
    hasnext = invokemember(enumeratorty, enumerator, :MoveNext)
    hasnext || return nothing
    next = invokemember(enumeratorty, enumerator, :Current)
    return (next, (enumerator, enumeratorty))
end

function clreltype(obj::CLRObject)
    ty = clrtypeof(obj)
    if isassignable(T"System.Collections.IEnumerable", ty) && invokemember(T"System.Type", ty, :IsGenericType)
        return arrayload(invokemember(T"System.Type", ty, :GetGenericArguments), 0)
    end
    invokemember(T"System.Type", ty, :GetElementType)
end

function Base.eltype(obj::CLRObject)
    elt = clreltype(obj)
    typestr = string(isnull(elt) ? clrtypeof(obj) : elt)
    return if haskey(TYPES_TO_UNBOX, typestr)
        TYPES_TO_UNBOX[typestr][1]
    else
        CLRObject
    end
end

function Base.length(obj::CLRObject)
    objty = clrtypeof(obj)
    if isassignable(T"System.Array", objty)
        invokemember(T"System.Array", obj, :Length)
    elseif isassignable(T"System.Collections.IList", objty)
        invokemember(obj, :Count)
    else
        throw(ArgumentError("Cannot determine length from type $objty"))
    end
end

function arrayof(elty::CLRObject, dims)
    invokemember(T"System.Array", CLRObject(0), :CreateInstance, elty, dims...)
end

function arraystore(arr::CLRObject, index, x)
    invokemember(T"System.Array", arr, :SetValue, x, index...)
end

function arrayload(arr::CLRObject, index)
    invokemember(T"System.Array", arr, :GetValue, index...)
end

makearraytype(ty::CLRObject, rank) = invokemember(ty, :MakeArrayType, rank)

function box(x::AbstractArray{T,N}, handle) where {T,N}
    a = arrayof(boxedtype(T), size(x))
    clrind = CartesianIndices(size(x))
    for i in LinearIndices(x)
        arraystore(a, Tuple(clrind[i]) .- 1, x[i])
    end
    return gethandle(a)
end

boxedtype(::Type{AbstractArray{T,N}}) where {T,N} = makearraytype(boxedtype(T), N)
