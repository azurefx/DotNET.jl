module CoreCLR

using Libdl

import ...CLR:HRESULT,isfailed,CLRHostError,CLRHost,create_host,create_delegate
export CoreCLRHost

const fp_coreclr_initialize = Ref{Ptr{Cvoid}}(0)
const fp_coreclr_shutdown = Ref{Ptr{Cvoid}}(0)
const fp_coreclr_create_delegate = Ref{Ptr{Cvoid}}(0)

function init(coreclr_dll::AbstractString)
    h = dlopen(coreclr_dll)
    fp_coreclr_initialize[] = dlsym(h, :coreclr_initialize)
    fp_coreclr_shutdown[] = dlsym(h, :coreclr_shutdown)
    fp_coreclr_create_delegate[] = dlsym(h, :coreclr_create_delegate)
    nothing
end

const TPA_DELIM = @static Sys.iswindows() ? ";" : ":"

struct CoreCLRHost <: CLRHost
    handle::Ptr{Cvoid}
    domain_id::UInt32
end

function create_host(::Type{CoreCLRHost};tpalist = []) 
    propk = [
        "TRUSTED_PLATFORM_ASSEMBLIES"
    ]
    propv = [
        join(tpalist, TPA_DELIM)
    ]
    host = Ref{Ptr{Cvoid}}()
    domain_id = Ref{UInt32}()
    hr = coreclr_initialize(@__DIR__, "Julia", 1, propk, propv, host, domain_id)
    if isfailed(hr)
        throw(CLRHostError("Failed to initialize CoreCLR", hr))
    end
    return CoreCLRHost(host[], domain_id[])
end

function create_delegate(host::CoreCLRHost, assembly, type, method)
    delegate = Ref{Ptr{Cvoid}}()
    hr = coreclr_create_delegate(host, assembly, type, method, delegate)
    if isfailed(hr)
        throw(CLRHostError("Failed to create delegate for $((assembly, type, method))", hr))
    end
    return delegate[]
end

function coreclr_initialize(exePath,
    appDomainFriendlyName,
    propertyCount,
    propertyKeys,
    propertyValues,
    hostHandle,
    domainId)
    ccall(fp_coreclr_initialize[], HRESULT,
    (Cstring, Cstring, Int32, Ptr{Ptr{UInt8}}, Ptr{Ptr{UInt8}}, Ptr{Ptr{Cvoid}}, Ptr{UInt32}),
    exePath, appDomainFriendlyName, propertyCount, propertyKeys, propertyValues, hostHandle, domainId)
end

function coreclr_shutdown(host::CoreCLRHost)
    ccall(fp_coreclr_shutdown[], HRESULT, (Ptr{Cvoid}, UInt32), host.handle, host.domain_id)
end

function coreclr_create_delegate(host::CoreCLRHost,
    entryPointAssemblyName,
    entryPointTypeName,
    entryPointMethodName,
    delegate)
    return ccall(fp_coreclr_create_delegate[], HRESULT,
    (Ptr{Cvoid}, UInt32, Cstring, Cstring, Cstring, Ptr{Ptr{Cvoid}}),
    host.handle, host.domain_id, entryPointAssemblyName, entryPointTypeName, entryPointMethodName, delegate)
end

end
