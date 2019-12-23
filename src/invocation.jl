function invoke_member(flags, type::CLRObject, this::CLRObject, name, args...)
    boxed = map(args, 1:length(args)) do arg, i
        box(arg, i).handle
    end
    unbox(CLRBridge.InvokeMember(type.handle, string(name), flags, 0, this.handle, boxed))
end

function invoke_member(type::CLRObject, this::CLRObject, name, args...)
    flags = BindingFlags.InvokeMethod | BindingFlags.GetField | BindingFlags.GetProperty
    invoke_member(flags, type, this, name, args...)
end
