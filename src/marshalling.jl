const TYPES_TO_UNBOX = Dict{String,Tuple{Type,Function}}()

let
    unboxer(clrname, jltype, getter) = begin
        TYPES_TO_UNBOX[clrname] = (jltype, getter)
    end
    unboxer("System.Boolean", Bool, CLRBridge.GetBool)
    unboxer("System.SByte", Int8, CLRBridge.GetInt8)
    unboxer("System.Byte", UInt8, CLRBridge.GetUInt8)
    unboxer("System.Int16", Int16, CLRBridge.GetInt16)
    unboxer("System.UInt16", UInt16, CLRBridge.GetUInt16)
    unboxer("System.Int32", Int32, CLRBridge.GetInt32)
    unboxer("System.UInt32", UInt32, CLRBridge.GetUInt32)
    unboxer("System.Int64", Int64, CLRBridge.GetInt64)
    unboxer("System.UInt64", UInt64, CLRBridge.GetUInt64)
    unboxer("System.Single", Float32, CLRBridge.GetFloat32)
    unboxer("System.Double", Float64, CLRBridge.GetFloat64)
    unboxer("System.Char", Char, CLRBridge.GetChar)
    unboxer("System.String", String, CLRBridge.GetString)
end

function unbox(obj::CLRObject)
    isnull(obj) && return obj
    typename = string(clrtypeof(obj))
    if haskey(TYPES_TO_UNBOX, typename)
        return TYPES_TO_UNBOX[typename][2](gethandle(obj))
    else
        return obj
    end
end

box(x::CLRObject, handle) = gethandle(x)
boxedtype(::Type{CLRObject}) = T"System.Object"
box(x::Bool, handle) = CLRBridge.PutBool(handle, x)
boxedtype(::Type{Bool}) = T"System.Boolean"
box(x::Int8, handle) = CLRBridge.PutInt8(handle, x)
boxedtype(::Type{Int8}) = T"System.SByte"
box(x::UInt8, handle) = CLRBridge.PutUInt8(handle, x)
boxedtype(::Type{UInt8}) = T"System.Byte"
box(x::Int16, handle) = CLRBridge.PutInt16(handle, x)
boxedtype(::Type{Int16}) = T"System.Int16"
box(x::UInt16, handle) = CLRBridge.PutUInt16(handle, x)
boxedtype(::Type{UInt16}) = T"System.UInt16"
box(x::Int32, handle) = CLRBridge.PutInt32(handle, x)
boxedtype(::Type{Int32}) = T"System.Int32"
box(x::UInt32, handle) = CLRBridge.PutUInt32(handle, x)
boxedtype(::Type{UInt32}) = T"System.UInt32"
box(x::Int64, handle) = CLRBridge.PutInt64(handle, x)
boxedtype(::Type{Int64}) = T"System.Int64"
box(x::UInt64, handle) = CLRBridge.PutUInt64(handle, x)
boxedtype(::Type{UInt64}) = T"System.UInt64"
box(x::Float32, handle) = CLRBridge.PutFloat32(handle, x)
boxedtype(::Type{Float32}) = T"System.Single"
box(x::Float64, handle) = CLRBridge.PutFloat64(handle, x)
boxedtype(::Type{Float64}) = T"System.Double"
box(x::Char, handle) = CLRBridge.PutChar(handle, x)
boxedtype(::Type{Char}) = T"System.Char"
box(x::String, handle) = CLRBridge.PutString(handle, x)
boxedtype(::Type{String}) = T"System.String"

function Base.convert(::Type{CLRObject}, x)
    CLRBridge.Duplicate(box(x, 1))
end

Base.convert(::Type{CLRObject}, x::CLRObject) = x

function invokemember(flags, type::CLRObject, this::CLRObject, name, args...)
    boxed = map(args, 1:length(args)) do arg, i
        box(arg, i)
    end
    unbox(CLRBridge.InvokeMember(gethandle(type), string(name), flags, 0, gethandle(this), boxed))
end

function invokemember(type::CLRObject, this::CLRObject, name, args...)
    flags = BindingFlags.InvokeMethod | BindingFlags.GetField | BindingFlags.GetProperty
    invokemember(flags, type, this, name, args...)
end

invokemember(this::CLRObject, name, args...) = invokemember(clrtypeof(this), this, name, args...)

include("array.jl")
