using Test
using DotNET
import DotNET:unbox, makegenerictype

@testset "Type Loader" begin
    @test T"System.Int64".Name == "Int64"
    @test T"System.String".Name == "String"
    @test T"System.Console, mscorlib".Name == "Console"
    @test_throws CLRException T"BadType.KUUPXXCL"
end # testset

@testset "Marshaller" begin
    uturn(x) = @test (unbox(convert(CLRObject, x)) === x);true
    uturn(Int8(42))
    uturn(UInt8(42))
    uturn(Int16(42))
    uturn(UInt16(42))
    uturn(Int32(42))
    uturn(UInt32(42))
    uturn(Int64(42))
    uturn(UInt64(42))
    uturn('A')
    uturn("Hello, World!")
    array = convert(CLRObject, [1,2,3])
    @test collect(array) == [1,2,3]
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
end

@testset "Type System" begin
    li = convert(CLRObject, Int64[1])
    @test eltype(collect(li)) == Int64
    List = T"System.Collections.Generic.List`1"
    li = List.new[T"System.Int64"]()
    li.Add(Int64(1))
    @test eltype(collect(li)) == Int64
end

@testset "Delegate" begin
    ICollectionT = T"System.Collections.Generic.ICollection`1, mscorlib"
    ListT = T"System.Collections.Generic.List`1, mscorlib"
    collint = makegenerictype(ICollectionT, T"System.Int32")
    listint = makegenerictype(ListT, T"System.Int32")
    li = listint.new()
    refeq(a, b) = T"System.Object".ReferenceEquals(a, b)
    delegate(()->li.Add(Int32(1)), T"System.Action").Invoke()
    @test collect(li) == Int32[1]
    @test refeq(delegate(identity, makegenerictype(T"System.Func`2", listint, listint)).Invoke(li), li)
    @test refeq(delegate(identity, makegenerictype(T"System.Func`2", collint, listint)).Invoke(li), li)
    @test refeq(delegate(identity, makegenerictype(T"System.Func`2", listint, collint)).Invoke(li), li)
    @test refeq(delegate(identity, makegenerictype(T"System.Func`2", collint, collint)).Invoke(li), li)
    @test delegate(x->2x, T"System.Func`2[System.Int32, System.Int32]").Invoke(Int32(1)) === Int32(2)
    @test delegate(x->2x, T"System.Func`2[System.Int32, System.UInt64]").Invoke(Int32(1)) === UInt64(2)
end
