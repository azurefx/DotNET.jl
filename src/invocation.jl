function invoke_static(type::CLRObject, name, args...)
    BindingFlags = CLRBridge.BindingFlags
    flags = BindingFlags.InvokeMethod
    boxed = map(args, 1:length(args)) do arg, i
        box(arg, i).handle
    end
    CLRBridge.InvokeMember(type.handle, string(name), flags, 0, 0, boxed)
end
