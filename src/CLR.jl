module CLR

import Pkg.Artifacts:@artifact_str

export CLRObject,null,isnull,CLRException,@T_str,
    clrtypeof,isclrtype,isassignable,
    clreltype

include("typedef.jl")

include("CoreCLR.jl")
using .CoreCLR

include("CLRBridge.jl")
using .CLRBridge

include("typeinfo.jl")

include("marshalling.jl")

include("callback.jl")

include("reflection.jl")

include("operators.jl")

struct DummyCLRHost <: CLRHost end

const CURRENT_CLR_HOST = Ref{CLRHost}(DummyCLRHost())

function __init__()
    if CURRENT_CLR_HOST[] != DummyCLRHost() return end
    coreclr = detect_runtime(CoreCLRHost)
    if !isempty(coreclr)
        init_coreclr(first(coreclr))
        return
    end
    @error """
    No .NET Core runtime found on this system.
    Try specifying DOTNET_ROOT environment variable or adding 'dotnet' executable to PATH, then run 'CLR.__init__()' again.
    Note that .NET Framework is current not supported.
    """
end

function init_coreclr(runtime)
    CoreCLR.init(runtime)
    dir = artifact"clrbridge"
    clrbridge = joinpath(dir, "CLRBridge.dll")
    if !isfile(clrbridge)
        error("""
        Artifact is present but CLRBridge.dll not found, possibly due to a broken package installation.
        You may need to delete the artifact directory '$dir' and try 'CLR.__init__()' again.
        """)
    end
    tpalist = build_tpalist(dirname(runtime.path))
    push!(tpalist, clrbridge)
    CURRENT_CLR_HOST[] = create_host(CoreCLRHost;tpalist = tpalist)
    CLRBridge.init(CURRENT_CLR_HOST[])
end

function build_tpalist(dir)
    joinpath.(dir, filter(x->splitext(x)[2] == ".dll", readdir(dir)))
end

end # module
