function dispatch_callback(f::Function, argc)
    argv = map(1:argc) do i
        unbox(CLRObject(i))
    end
    result = f(argv...)
    return box(result, 1)
end

function delegate(f::Function, delty::CLRObject)
    context = objectid(f)
    d = CLRBridge.CreateDelegate(gethandle(delty), context)
    CLRBridge.registered_callbacks[context] = argc->dispatch_callback(f, argc)
    return d
end
