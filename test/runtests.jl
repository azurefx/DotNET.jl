using Test
using DotNET
import DotNET: unbox, arrayof

@testset "Type Loader" begin
    @test T"System.Int64".Name == "Int64"
    @test T"System.String".Name == "String"
    @test T"System.Console, mscorlib".Name == "Console"
    @test_throws CLRException T"BadType.KUUPXXCL"
end # testset

@testset "Marshaller" begin
    uturn(x) = @test (unbox(convert(CLRObject, x)) === x)
    true
    uturn(Int8(42))
    uturn(UInt8(42))
    uturn(Int16(42))
    uturn(UInt16(42))
    uturn(Int32(42))
    uturn(UInt32(42))
    uturn(Int64(42))
    uturn(UInt64(42))
    uturn(Float32(42))
    uturn(Float64(42))
    uturn('A')
    uturn("Hello, World!")
    array = convert(CLRObject, [1, 2, 3])
    @test collect(array) == [1, 2, 3]
    for (i, x) in enumerate(array)
        @test x == i
    end
end

@testset "Member Invocation" begin
    ArrayList = T"System.Collections.ArrayList, mscorlib"
    li = ArrayList.new()
    li.Add(42)
    @test li.Count == 1
    ListT = T"System.Collections.Generic.List`1, mscorlib"
    li = ListT.new[T"System.Int64"]()
    li.Add(42)
    @test li.Count == 1
    @test isclrtype(T"System.Array".Empty[T"System.Int64"](), T"System.Int64[]")
    WeakReference = T"System.WeakReference, mscorlib"
    ref = WeakReference.new(CLRObject(0))
    ref.Target = WeakReference
    @test T"System.Object, mscorlib".Equals(ref.Target, WeakReference)

    # varargs
    @test T"System.String".Format("{0}{1}{2}", "i", 18, "n") == "i18n"

    # field access
    let t = T"System.ValueTuple`1".new[T"System.Int32"](Int32(1))
        @test t.Item1 == Int32(1)
        t.Item1 = Int32(2)
        @test t.Item1 == Int32(2)
    end

    # out parameters
    let
        tryparse(s, i) = T"System.Int64".TryParse(s, i)
        @test tryparse("42", null)
        @test !tryparse("abc", null)
        r = Ref{Int64}()
        @test !tryparse("abc", r)
        tryparse("123", r)
        @test r[] == 123
        r = Ref{CLRObject}()
        tryparse("def", r)
        @test unbox(r[]) == 0
        tryparse("456", r)
        @test unbox(r[]) == 456
        r = Ref{CLRObject}(1)
        tryparse("789", r)
        @test unbox(r[]) == 789
    end
end

@testset "Generics" begin
    List = T"System.Collections.Generic.List`1"
    li = List.new[T"System.Int64"]()
    li.Add(Int64(1))
    @test eltype(collect(li)) == Int64
end

@testset "Arrays and Iteration" begin
    @test eltype(convert(CLRObject, Int64[1])) == Int64
    jlarr = reshape(1:24, (2, 3, 4))
    arr = convert(CLRObject, jlarr)
    @test axes(arr) == (2, 3, 4)
    @test collect(arr) == jlarr
    ch = Channel() do ch
        e = arr.GetEnumerator()
        while e.MoveNext()
            put!(ch, e.Current)
        end
    end
    @test collect(ch) == jlarr[:]
end
