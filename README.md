# DotNET.jl

[![Build Status](https://github.com/azurefx/DotNET.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/azurefx/DotNET.jl/actions/workflows/ci.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

This package provides interoperability between Julia and [`Common Language Runtime`](https://docs.microsoft.com/dotnet/standard/clr), the execution engine of `.NET` applications. Many languages run on CLR, including `C#`, `Visual Basic .NET` and `PowerShell`.

## Prerequisites

- `Julia` version 1.3+
- `.NET Core Runtime` version 2.2+ ([Download](https://dotnet.microsoft.com/download))

`WinForms` and other GUI-related features require a [desktop runtime](https://github.com/azurefx/DotNET.jl/issues/11).

If the package fails to locate the runtime, set `DOTNET_ROOT` environment variable to the path containing the `dotnet` or `dotnet.exe` binary.

`.NET Framework` is not supported yet.

## Installation

In the REPL, type `]add DotNET` and press `Enter`.
```
(v1.x) pkg> add DotNET
```

Or use `Pkg.add` for [more options](https://pkgdocs.julialang.org/v1/api/):

```julia
julia> using Pkg

julia> Pkg.add(PackageSpec(url = "https://github.com/azurefx/DotNET.jl"))
```

## Usage

```julia
julia> using DotNET
```

### Types and Objects

`DotNET.jl` provides the [`T"AssemblyQualifiedTypeName"`](https://docs.microsoft.com/dotnet/standard/assembly/find-fully-qualified-name) literal for type reference:

```julia
julia> Console = T"System.Console, mscorlib"
System.Console
```

Given a type object, you can access its properties or methods using the dot operator:

```julia
julia> Console.WriteLine("Hello from .NET!");
Hello from .NET!
```

To create an object, use the `new` syntax:

```julia
julia> T"System.Guid".new("CA761232-ED42-11CE-BACD-00AA0057B223")
System.Guid("ca761232-ed42-11ce-bacd-00aa0057b223")
```

All `.NET` objects are represented by `CLRObject`s in Julia, including types:

```julia
julia> typeof(Console)
CLRObject

julia> typeof(null)
CLRObject
```

`null` is a built-in object that does not refer to a valid `.NET` object. When you try to access a member on a `null` value, a `System.NullReferenceException` is thrown.

Arguments passed to `.NET` methods are automatically converted to `CLRObject`s, and return values are converted to corresponding Julia types:

```julia
julia> T"System.Convert".ToInt64("42")
42
```

Or you could do some explicit conversions:

```julia
julia> s = convert(CLRObject, "❤")
System.String("❤")

julia> DotNET.unbox(s)
"❤"
```

To pass an argument by reference (`out`/`ref` in `C#`), wrap it into a `Ref` object:

```julia
julia> result = Ref{Int}()
Base.RefValue{Int64}(212700848)

julia> T"System.Int64".TryParse("1970", result)
true

julia> result[]
1970

julia> result = Ref(null)
Base.RefValue{CLRObject}(null)

julia> T"System.Int64".TryParse("2022", result)
true

julia> result[]
System.Int64(2022)
```

### Arrays and Collections

To copy a multidimensional array from `.NET` to Julia, use `collect` method:

```julia
julia> arr = convert(CLRObject, reshape(1:8, 2, 2, 2))
System.Int64[,,]("System.Int64[,,]")

julia> collect(arr)
2×2×2 Array{Int64, 3}:
[:, :, 1] =
 1  3
 2  4

[:, :, 2] =
 5  7
 6  8
```

CLI `Array` elements are stored in *row-major* order, thus the equivalent definition in `C#` is
```csharp
public static long[,,] Get3DArray() {
  return new long[2, 2, 2] {
    {{1, 2}, {3, 4}},
    {{5, 6}, {7, 8}}
  };
}
```

To index into arrays, use `arraystore` and `arrayload` methods. Note that CLI `Array`s use zero-based indexing.

```julia
julia> DotNET.arraystore(arr, (1, 1, 1), 0)
null

julia> DotNET.arrayload(arr, (1, 1, 1)) == collect(arr)[2, 2, 2]
true
```

If an object implements `IEnumerable` interface, you can call `GetEnumerator` to iterate over the array:
```julia
julia> ch = Channel() do it
           e = arr.GetEnumerator()
           while e.MoveNext()
               put!(it, e.Current)
           end
       end
Channel{Any}(0) (1 item available)

julia> collect(ch)
8-element Vector{Any}:
 1
 ⋮
 8
```

Or just use the `for-in` loop:
```julia
for x in arr
    println(x)
end
```

### Loading External Assemblies

If you have a `DLL` file, you can load it using reflection:

```julia
julia> T"System.Reflection.Assembly".LoadFrom(raw"C:\Users\Azure\Desktop\test.dll")
System.Reflection.RuntimeAssembly("test, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null")
```

Now you have access to types defined in the assembly.

### Generics

Generic types are be expressed in the following ways:

```julia
julia> ListT = T"System.Collections.Generic.List`1"
System.Collections.Generic.List`1[T]

julia> ListInt64 = T"System.Collections.Generic.List`1[System.Int64]"
System.Collections.Generic.List`1[System.Int64]
```

The number `1` after the backtick indicates the type `System.Collections.Generic.List<T>` has one type parameter. `ListT` has a free type variable, just like `Vector{T} where T` in Julia. A type that includes at least one type argument is called a *constructed type*. `ListInt64` is a constructed type.

One can substitute type variables and make a constructed type by calling `makegenerictype` method:

```julia
julia> DotNET.makegenerictype(ListT, T"System.String")
System.Collections.Generic.List`1[System.String]
```


To invoke a generic method, put type arguments into square brackets:
```julia
julia> list = ListT.new[T"System.Int64"]()
System.Collections.Generic.List`1[System.Int64]("System.Collections.Generic.List`1[System.Int64]")
```

### Delegates

To create a delegate from a Julia method, use `delegate` method:

```julia
julia> list = ListT.new[T"System.Int64"](1:5)
System.Collections.Generic.List`1[System.Int64]("System.Collections.Generic.List`1[System.Int64]")

julia> list.RemoveAll(delegate(iseven, T"System.Predicate`1[System.Int64]"))
2

julia> collect(list)
3-element Vector{Int64}:
 1
 3
 5
```

<!-- 
- Implicit conversions when calling CLR methods
- More operators
- `using` directive like C#
- Smart assembly/type resolution
- Configurable runtime versions
- .NET Framework support
- PowerShell support (maybe in another package) -->
