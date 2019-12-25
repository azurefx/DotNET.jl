const types_to_unbox = Dict{String,Function}()
const types_to_box = Dict{DataType,Function}()

function init_marshaller()
    unboxer(clrname, getter) = begin
        types_to_unbox[clrname] = getter
    end
    unboxer("System.Boolean", CLRBridge.GetBool)
    unboxer("System.SByte", CLRBridge.GetInt8)
    unboxer("System.Byte", CLRBridge.GetUInt8)
    unboxer("System.Int16", CLRBridge.GetInt16)
    unboxer("System.UInt16", CLRBridge.GetUInt16)
    unboxer("System.Int32", CLRBridge.GetInt32)
    unboxer("System.UInt32", CLRBridge.GetUInt32)
    unboxer("System.Int64", CLRBridge.GetInt64)
    unboxer("System.UInt64", CLRBridge.GetUInt64)
    unboxer("System.Char", CLRBridge.GetChar)
    unboxer("System.String", CLRBridge.GetString)
    boxer(jltype, setter) = begin
        types_to_box[jltype] = setter
    end
    boxer(Bool, CLRBridge.PutBool)
    boxer(Int8, CLRBridge.PutInt8)
    boxer(UInt8, CLRBridge.PutUInt8)
    boxer(Int16, CLRBridge.PutInt16)
    boxer(UInt16, CLRBridge.PutUInt16)
    boxer(Int32, CLRBridge.PutInt32)
    boxer(UInt32, CLRBridge.PutUInt32)
    boxer(Int64, CLRBridge.PutInt64)
    boxer(UInt64, CLRBridge.PutUInt64)
    boxer(Char, CLRBridge.PutChar)
    boxer(String, CLRBridge.PutString)
end

function unbox(obj::CLRObject)
    gethandle(obj) == 0 && return obj
    typename = CLRBridge.GetString(gethandle(clrtypeof(obj)))
    if haskey(types_to_unbox, typename)
        return types_to_unbox[typename](gethandle(obj))
    else
        return obj
    end
end

box(x::CLRObject, handle) = x

function box(x, handle)
    type = typeof(x)
    if haskey(types_to_box, type)
        CLRObject(types_to_box[type](handle, x))
    else
        throw(ArgumentError("Cannot marshal objects of Julia type $type"))
    end
end

function invokemember(flags, type::CLRObject, this::CLRObject, name, args...)
    boxed = map(args, 1:length(args)) do arg, i
        gethandle(box(arg, i))
    end
    unbox(CLRBridge.InvokeMember(gethandle(type), string(name), flags, 0, gethandle(this), boxed))
end

function invokemember(type::CLRObject, this::CLRObject, name, args...)
    flags = BindingFlags.InvokeMethod | BindingFlags.GetField | BindingFlags.GetProperty
    invokemember(flags, type, this, name, args...)
end

function Base.iterate(obj::CLRObject)
    gethandle(obj) == 0 && return nothing
    objty = clrtypeof(obj)
    enumerablety = Type"System.Collections.IEnumerable"
    if !isassignable(enumerablety, objty)
        throw(ArgumentError("Object is not iterable"))
    end
    enumerator = invokemember(enumerablety, obj, :GetEnumerator)
    enumeratorty = Type"System.Collections.IEnumerator"
    hasnext = invokemember(enumeratorty, enumerator, :MoveNext)
    hasnext || return nothing
    next = invokemember(enumeratorty, enumerator, :Current)
    return (next, (enumerator, enumeratorty))
end

function Base.iterate(::CLRObject, state)
    enumerator, enumeratorty = state
    hasnext = invokemember(enumeratorty, enumerator, :MoveNext)
    hasnext || return nothing
    next = invokemember(enumeratorty, enumerator, :Current)
    return (next, (enumerator, enumeratorty))
end

function Base.eltype(obj::CLRObject)
    invokemember(Type"System.Type", clrtypeof(obj), :GetElementType)
end

function Base.length(obj::CLRObject)
    objty = clrtypeof(obj)
    if isassignable(Type"System.Array", objty)
        invokemember(Type"System.Array", obj, :Length)
    else
        throw(ArgumentError("Cannot determine length from type $objty"))
    end
end
