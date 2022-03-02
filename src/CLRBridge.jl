module CLRBridge

import ...DotNET:HRESULT,isfailed,CLRHostError,BStr,CLRHost,create_host,create_delegate
export CLRObject,null,isnull,gethandle,CLRException,BindingFlags

const Handle = UInt

mutable struct CLRObject
    handle::Handle
end

gethandle(obj::CLRObject) = getfield(obj, :handle)

const null = CLRObject(0)

isnull(obj::CLRObject) = gethandle(obj) == 0

function track(handle)
    obj = CLRObject(handle)
    if handle != 0
        finalizer(obj) do _
            Release(handle)
        end
    end
    obj
end

Base.string(x::CLRObject) = GetString(gethandle(x))

struct CLRException <: Exception
    message::String
    object::CLRObject
end

function Base.showerror(io::IO, ex::CLRException)
    print(io, "CLRException: $(ex.message)")
end

function track_and_throw(exhandle)
    exobj = track(exhandle)
    msg = try
        GetString(exhandle)
    catch ex
        "Failed to get exception description, caused by $ex"
    end
    throw(CLRException(msg, exobj))
end

empty_fp() = Ref{Ptr{Cvoid}}(0)

const fp_Release = empty_fp()
const fp_Duplicate = empty_fp()
const fp_CreateArray = empty_fp()
const fp_PutObject = empty_fp()
const fp_PutString = empty_fp()
const fp_GetString = empty_fp()
const fp_FreeString = empty_fp()
const fp_PutChar = empty_fp()
const fp_GetChar = empty_fp()
const fp_PutBool = empty_fp()
const fp_GetBool = empty_fp()
const fp_PutInt8 = empty_fp()
const fp_GetInt8 = empty_fp()
const fp_PutUInt8 = empty_fp()
const fp_GetUInt8 = empty_fp()
const fp_PutInt16 = empty_fp()
const fp_GetInt16 = empty_fp()
const fp_PutUInt16 = empty_fp()
const fp_GetUInt16 = empty_fp()
const fp_PutInt32 = empty_fp()
const fp_GetInt32 = empty_fp()
const fp_PutUInt32 = empty_fp()
const fp_GetUInt32 = empty_fp()
const fp_PutInt64 = empty_fp()
const fp_GetInt64 = empty_fp()
const fp_PutUInt64 = empty_fp()
const fp_GetUInt64 = empty_fp()
const fp_PutFloat32 = empty_fp()
const fp_GetFloat32 = empty_fp()
const fp_PutFloat64 = empty_fp()
const fp_GetFloat64 = empty_fp()

const fp_GetType = empty_fp()
const fp_GetObjectType = empty_fp()
const fp_InvokeMember = empty_fp()

const fp_SetCallbackHandler = empty_fp()
const fp_CreateDelegate = empty_fp()

const registered_callbacks = Dict{UInt,Function}()

function handle_callback(context, argc)
    if !haskey(registered_callbacks, context)
        error("Callback function not registered")
    end
    fn = registered_callbacks[context]
    return Handle(fn(argc))
end

function init(host::CLRHost)
    fp_primitive(x) = create_delegate(host, "CLRBridge", "CLRBridge.Primitive", x)
    fp_Release[] = fp_primitive("Release")
    fp_Duplicate[] = fp_primitive("Duplicate")
    fp_CreateArray[] = fp_primitive("CreateArray")
    fp_PutObject[] = fp_primitive("PutObject")
    fp_PutString[] = fp_primitive("PutString")
    fp_GetString[] = fp_primitive("GetString")
    fp_FreeString[] = fp_primitive("FreeString")
    fp_PutChar[] = fp_primitive("PutChar")
    fp_GetChar[] = fp_primitive("GetChar")
    fp_PutBool[] = fp_primitive("PutBool")
    fp_GetBool[] = fp_primitive("GetBool")
    fp_PutInt8[] = fp_primitive("PutInt8")
    fp_GetInt8[] = fp_primitive("GetInt8")
    fp_PutUInt8[] = fp_primitive("PutUInt8")
    fp_GetUInt8[] = fp_primitive("GetUInt8")
    fp_PutInt16[] = fp_primitive("PutInt16")
    fp_GetInt16[] = fp_primitive("GetInt16")
    fp_PutUInt16[] = fp_primitive("PutUInt16")
    fp_GetUInt16[] = fp_primitive("GetUInt16")
    fp_PutInt32[] = fp_primitive("PutInt32")
    fp_GetInt32[] = fp_primitive("GetInt32")
    fp_PutUInt32[] = fp_primitive("PutUInt32")
    fp_GetUInt32[] = fp_primitive("GetUInt32")
    fp_PutInt64[] = fp_primitive("PutInt64")
    fp_GetInt64[] = fp_primitive("GetInt64")
    fp_PutUInt64[] = fp_primitive("PutUInt64")
    fp_GetUInt64[] = fp_primitive("GetUInt64")
    fp_PutFloat32[] = fp_primitive("PutFloat32")
    fp_GetFloat32[] = fp_primitive("GetFloat32")
    fp_PutFloat64[] = fp_primitive("PutFloat64")
    fp_GetFloat64[] = fp_primitive("GetFloat64")
    fp_meta(x) = create_delegate(host, "CLRBridge", "CLRBridge.Meta", x)
    fp_GetType[] = fp_meta("GetType")
    fp_GetObjectType[] = fp_meta("GetObjectType")
    fp_InvokeMember[] = fp_meta("InvokeMember")
    fp_callback(x) = create_delegate(host, "CLRBridge", "CLRBridge.Callback", x)
    fp_SetCallbackHandler[] = fp_callback("SetCallbackHandler")
    fp_CreateDelegate[] = fp_callback("CreateDelegate")
    handler = @cfunction(handle_callback,Handle,(UInt, UInt32))
    SetCallbackHandler(handler)
    nothing
end

function Release(handle)
    ccall(fp_Release[], Bool, (Handle,), handle)
end

function Duplicate(handle)
    track(ccall(fp_Duplicate[], Handle, (Handle,), handle))
end

function CreateArray(argc)
    track(ccall(fp_CreateArray[], Handle, (UInt32,), argc))
end

function PutObject(handle, value)
    ccall(fp_PutObject[], Handle, (Handle, Handle), handle, value)
end

function PutString(handle, value)
    ccall(fp_PutString[], Handle, (Handle, BStr), handle, value)
end

function GetString(handle)
    bstr = ccall(fp_GetString[], BStr, (Handle,), handle)
    s = unsafe_string(bstr)
    FreeString(bstr)
    return s
end

function FreeString(bstr)
    ccall(fp_FreeString[], Cvoid, (BStr,), bstr)
end

function PutChar(handle, value)
    ccall(fp_PutChar[], Handle, (Handle, UInt16), handle, value)
end

function GetChar(handle)
    Char(ccall(fp_GetChar[], UInt16, (Handle,), handle))
end

function PutBool(handle, value)
    ccall(fp_PutBool[], Handle, (Handle, Bool), handle, value)
end

function GetBool(handle)
    ccall(fp_GetBool[], Bool, (Handle,), handle)
end

function PutInt8(handle, value)
    ccall(fp_PutInt8[], Handle, (Handle, Int8), handle, value)
end

function GetInt8(handle)
    ccall(fp_GetInt8[], Int8, (Handle,), handle)
end

function PutUInt8(handle, value)
    ccall(fp_PutUInt8[], Handle, (Handle, UInt8), handle, value)
end

function GetUInt8(handle)
    ccall(fp_GetUInt8[], UInt8, (Handle,), handle)
end

function PutInt16(handle, value)
    ccall(fp_PutInt16[], Handle, (Handle, Int16), handle, value)
end

function GetInt16(handle)
    ccall(fp_GetInt16[], Int16, (Handle,), handle)
end

function PutUInt16(handle, value)
    ccall(fp_PutUInt16[], Handle, (Handle, UInt16), handle, value)
end

function GetUInt16(handle)
    ccall(fp_GetUInt16[], UInt16, (Handle,), handle)
end

function PutInt32(handle, value)
    ccall(fp_PutInt32[], Handle, (Handle, Int32), handle, value)
end

function GetInt32(handle)
    ccall(fp_GetInt32[], Int32, (Handle,), handle)
end

function PutUInt32(handle, value)
    ccall(fp_PutUInt32[], Handle, (Handle, UInt32), handle, value)
end

function GetUInt32(handle)
    ccall(fp_GetUInt32[], UInt32, (Handle,), handle)
end

function PutInt64(handle, value)
    ccall(fp_PutInt64[], Handle, (Handle, Int64), handle, value)
end

function GetInt64(handle)
    ccall(fp_GetInt64[], Int64, (Handle,), handle)
end

function PutUInt64(handle, value)
    ccall(fp_PutUInt64[], Handle, (Handle, UInt64), handle, value)
end

function GetUInt64(handle)
    ccall(fp_GetUInt64[], UInt64, (Handle,), handle)
end

function PutFloat32(handle, value)
    ccall(fp_PutFloat32[], Handle, (Handle, Float32), handle, value)
end

function GetFloat32(handle)
    ccall(fp_GetFloat32[], Float32, (Handle,), handle)
end

function PutFloat64(handle, value)
    ccall(fp_PutFloat64[], Handle, (Handle, Float64), handle, value)
end

function GetFloat64(handle)
    ccall(fp_GetFloat64[], Float64, (Handle,), handle)
end

function GetType(typename)
    exception = Ref{Handle}()
    ret = ccall(fp_GetType[], Handle, (BStr, Ptr{Handle}), typename, exception)
    if exception[] != 0
        track_and_throw(exception[])
    end
    return track(ret)
end

function GetObjectType(handle)
    ret = ccall(fp_GetObjectType[], Handle, (Handle,), handle)
    return track(ret)
end

baremodule BindingFlags

using Base:@enum
@enum BindingFlag::UInt32 begin
    Default = 0
    IgnoreCase = 1
    DeclaredOnly = 2
    Instance = 4
    Static = 8
    Public = 16
    NonPublic = 32
    FlattenHierarchy = 64
    InvokeMethod = 256
    CreateInstance = 512
    GetField = 1024
    SetField = 2048
    GetProperty = 4096
    SetProperty = 8192
    PutDispProperty = 16384
    PutRefDispProperty = 32768
    ExactBinding = 65536
    SuppressChangeType = 131072
    OptionalParamBinding = 262144
    IgnoreReturn = 16777216
end
end

import .BindingFlags:BindingFlag

Base.:(|)(a::BindingFlag, b::BindingFlag) = UInt32(a) | UInt32(b)
Base.:(|)(a::BindingFlag, b) = UInt32(a) | b
Base.:(|)(a, b::BindingFlag) = b | a

function InvokeMember(type, name, bindingFlags, binder, target, providedArgs)
    exception = Ref{Handle}()
    ret = ccall(fp_InvokeMember[], Handle,
    (Handle, BStr, UInt32, Handle, Handle, Ptr{Handle}, UInt32, Ptr{Handle}),
    type, name, bindingFlags, binder, target, providedArgs, length(providedArgs), exception)
    if exception[] != 0
        track_and_throw(exception[])
    end
    return track(ret)
end

function SetCallbackHandler(fp)
    ccall(fp_SetCallbackHandler[], Cvoid, (Ptr{Cvoid},), fp)
end

function CreateDelegate(htype, context)
    exception = Ref{Handle}()
    ret = ccall(fp_CreateDelegate[], Handle, (Handle, UInt, Ptr{Handle}), htype, context, exception)
    if exception[] != 0
        track_and_throw(exception[])
    end
    return track(ret)
end

end
