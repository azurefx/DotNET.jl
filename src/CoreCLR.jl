module CoreCLR

using Libdl

import ...DotNET:HRESULT,isfailed,CLRHostError,CLRHost,detect_runtime,create_host,create_delegate
export CoreCLRHost

const fp_coreclr_initialize = Ref{Ptr{Cvoid}}(0)
const fp_coreclr_shutdown = Ref{Ptr{Cvoid}}(0)
const fp_coreclr_create_delegate = Ref{Ptr{Cvoid}}(0)

function init(runtime)
    h = dlopen(runtime.path)
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

function detect_runtime(::Type{CoreCLRHost})
    try_get_io(dotnet_root) = begin
        dotnet_bin = joinpath(dotnet_root, "dotnet")
        io = IOBuffer()
        try
            t = @async run(pipeline(`$dotnet_bin --list-runtimes`;stdout = io))
            wait(t)
            seekstart(io)
            return io
        catch ex
            close(io)
            return nothing
        end
    end
    io = nothing
    if haskey(ENV, "DOTNET_ROOT")
        io = try_get_io(ENV["DOTNET_ROOT"])
    end
    if isnothing(io)
        io = try_get_io("")
    end
    if isnothing(io)
        io = @static if Sys.iswindows()
            try_get_io(joinpath(ENV["ProgramFiles"], "dotnet"))
        else
            try_get_io("/usr/local/share/dotnet")
        end
    end
    runtimes = []
    if !isnothing(io)
        for line in eachline(io)
            m = match(r"(\S*)\s*(\S*)\s*\[(.*)\]", line)
            if !isnothing(m) && length(m.captures) >= 3
                type, version, path = m.captures
                dllprefix = @static Sys.iswindows() ? "" : "lib"
                dllname = "$(dllprefix)coreclr.$(Libdl.dlext)"
                dllpath = joinpath(path, version, dllname)
                if isfile(dllpath)
                    try
                        push!(runtimes, (type = type, version = VersionNumber(version), path = dllpath))
                    catch
                    end
                end
            end
        end
        close(io)
    end
    return sort(runtimes;by = x->x.version,rev = true)
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
