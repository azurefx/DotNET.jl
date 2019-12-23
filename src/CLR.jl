module CLR

export CLRObject,null,CLRException,@Type_str
export clrtypeof,isclrtype

include("typedef.jl")

include("CoreCLR.jl")
using .CoreCLR

include("CLRBridge.jl")
using .CLRBridge

include("marshalling.jl")

include("invocation.jl")

struct DummyCLRHost <: CLRHost end

const CURRENT_CLR_HOST = Ref{CLRHost}(DummyCLRHost())

function build_tpalist(dir)
    joinpath.(dir, filter(x->splitext(x)[2] == ".dll", readdir(dir)))
end

function init_coreclr(::Type{CoreCLRHost})
    if CURRENT_CLR_HOST[] != DummyCLRHost() return end
    coreclr = raw"C:\Program Files\dotnet\shared\Microsoft.NETCore.App\3.0.1\coreclr.dll"
    clrbridge = raw"C:\Users\Azure\Documents\Git\CLRBridge\CLRBridge\bin\Debug\netstandard2.0\CLRBridge.dll"
    tpalist = build_tpalist(dirname(coreclr))
    push!(tpalist, clrbridge)
    CoreCLR.init(coreclr)
    CURRENT_CLR_HOST[] = create_host(CoreCLRHost;tpalist = tpalist)
    post_init()
    nothing
end

function post_init()
    CLRBridge.init(CURRENT_CLR_HOST[])
    init_marshaller()
end

macro Type_str(name)
    :(CLRBridge.GetType($name))
end

end # module
