struct HRESULT
    opaque::UInt32
end

issucceeded(x::HRESULT) = x.opaque >> 31 & 0x1 == 0
isfailed(x::HRESULT) = !issucceeded(x)
Base.convert(::Type{UInt32}, x::HRESULT) = x.opaque

function Base.show(io::IO, x::HRESULT)
    write(io, "HRESULT(")
    show(io, x.opaque)
    @static if Sys.iswindows()
        str = errmsg(x)
        if str != nothing
            write(io, " = ")
            show(io, errmsg(x))
        end
    end
    write(io, ")")
    nothing
end

@static if Sys.iswindows()
    function errmsg(hr::HRESULT)
        FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
        FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000
        FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200
        ptrbuf = Ref(Ptr{UInt16}(0))
        ccall(:FormatMessageW, stdcall,
            UInt32, (UInt32, Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}, UInt32, Ptr{Cvoid}),
            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            C_NULL, hr, 0, ptrbuf, 0, C_NULL)
        result = nothing
        if ptrbuf[] != C_NULL
            len = ccall(:wcslen, UInt, (Ptr{Cvoid},), ptrbuf[])
            strbuf = Array{UInt16}(undef, len)
            unsafe_copyto!(pointer(strbuf), ptrbuf[], len)
            result = chomp(String(transcode(UInt8, strbuf)))
            ccall(:LocalFree, stdcall, Ptr{Cvoid}, (Ptr{Cvoid},), ptrbuf[])
        end
        return result
    end
end

struct CLRHostError <: Exception
    prefix::AbstractString
    hr::HRESULT
end

function Base.showerror(io::IO, ex::CLRHostError)
    print(io, "CLRHostError: $(ex.prefix): $(ex.hr)")
end

primitive type BStr Sys.WORD_SIZE end

function Base.cconvert(::Type{BStr}, x::AbstractString)
    cunit = transcode(UInt16, x)
    cch = UInt32(length(cunit))
    buf = Vector{UInt16}(undef, cch + 3)
    ptr = Ptr{UInt32}(pointer(buf))
    unsafe_store!(ptr, cch * sizeof(UInt16))
    copyto!(buf, 3, cunit, 1, cch)
    buf[end] = 0
    return buf
end

function Base.unsafe_convert(::Type{BStr}, x::Vector{UInt16})
    return reinterpret(BStr, pointer(x) + sizeof(UInt32))
end

function Base.unsafe_string(bstr::BStr)
    ptr = reinterpret(Ptr{UInt16}, bstr)
    if ptr == C_NULL
        throw(UndefRefError())
    end
    cb = unsafe_load(Ptr{UInt32}(ptr - sizeof(UInt32)))
    buf = Vector{UInt16}(undef, ceil(Int, cb / sizeof(UInt16)))
    unsafe_copyto!(Ptr{UInt8}(pointer(buf)), Ptr{UInt8}(ptr), cb)
    return transcode(String, buf)
end

abstract type CLRHost end

function create_host end

function create_delegate end
