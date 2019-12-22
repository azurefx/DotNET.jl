module CLRBridge

import ...CLR:HRESULT,isfailed,CLRHostError,BStr,CLRHost,create_host,create_delegate 

const Handle = UInt

mutable struct CLRObject
    handle::Handle
end

function track(obj::CLRObject)
    if obj.handle != 0
        finalizer(obj) do x
            Release(x.handle)
        end
    end
    obj
end

function Base.show(io::IO, x::CLRObject)
    if x.handle == 0
        print(io, "null")
        return
    end
    print(io, GetString(GetObjectType(x.handle).handle))
    print(io, "(")
    print(io, repr(GetString(x.handle)))
    print(io, ")")
end

struct CLRException <: Exception
    message::String
    object::CLRObject
end

function Base.showerror(io::IO, ex::CLRException)
    print(io, "CLRException: $(ex.message)")
end

function track_and_throw(clrex::CLRObject)
    track(clrex)
    msg = try
        GetString(clrex.handle)
    catch ex
        "Failed to get exception description, caused by $ex"
    end
    throw(CLRException(msg, clrex))
end

empty_fp() = Ref{Ptr{Cvoid}}(0)

const fp_Release = empty_fp()
const fp_PutString = empty_fp()
const fp_GetString = empty_fp()
const fp_FreeString = empty_fp()
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

const fp_GetType = empty_fp()
const fp_GetObjectType = empty_fp()
const fp_InvokeMember = empty_fp()

function init(host::CLRHost)
    fp_primitive(x) = create_delegate(host, "CLRBridge", "CLRBridge.Primitive", x)
    fp_Release[] = fp_primitive("Release")
    fp_PutString[] = fp_primitive("PutString")
    fp_GetString[] = fp_primitive("GetString")
    fp_FreeString[] = fp_primitive("FreeString")
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
    fp_meta(x) = create_delegate(host, "CLRBridge", "CLRBridge.Meta", x)
    fp_GetType[] = fp_meta("GetType")
    fp_GetObjectType[] = fp_meta("GetObjectType")
    fp_InvokeMember[] = fp_meta("InvokeMember")
    nothing
end

function Release(handle)
    ccall(fp_Release[], Bool, (Handle,), handle)
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

function GetType(typename)
    exception = Ref{Handle}()
    ret = ccall(fp_GetType[], Handle, (BStr, Ptr{Handle}), typename, exception)
    if exception[] != 0
        track_and_throw(CLRObject(exception[]))
    end
    return track(CLRObject(ret))
end

function GetObjectType(handle)
    ret = ccall(fp_GetObjectType[], Handle, (Handle,), handle)
    return track(CLRObject(ret))
end

baremodule BindingFlags
using Base:@enum
@enum BindingFlag begin
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

function InvokeMember(type, name, bindingFlags, binder, target, providedArgs)
    exception = Ref{Handle}()
    ret = ccall(fp_InvokeMember[], Handle,
    (Handle, BStr, BindingFlags.BindingFlag, Handle, Handle, Ptr{Handle}, UInt64, Ptr{Handle}),
    type, name, bindingFlags, binder, target, providedArgs, length(providedArgs), exception)
    if exception[] != 0
        track_and_throw(CLRObject(exception[]))
    end
    if ret != 0
        return track(CLRObject(ret))
    else
        return CLRObject(0)
    end
end

end
