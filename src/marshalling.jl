function clrtypeof(x::CLRObject)
    CLRBridge.GetObjectType(x.handle)
end

function isclrtype(x::CLRObject, t::CLRObject)
    xt = clrtypeof(x)
    ret = CLRBridge.InvokeMember(clrtypeof(xt).handle, "Equals", CLRBridge.BindingFlags.InvokeMethod,
    0, xt.handle, [t.handle])
    return CLRBridge.GetBool(ret.handle)
end

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
    obj.handle == 0 && return obj
    typename = CLRBridge.GetString(clrtypeof(obj).handle)
    if haskey(types_to_unbox, typename)
        return types_to_unbox[typename](obj.handle)
    else
        return obj
    end
end

function box(x, handle)
    type = typeof(x)
    if haskey(types_to_box, type)
        CLRObject(types_to_box[type](handle, x))
    else
        throw(ArgumentError("Cannot marshal objects of Julia type $type"))
    end
end
