# DotNET.jl

[![Build Status](https://travis-ci.org/azurefx/DotNET.jl.svg?branch=master)](https://travis-ci.org/azurefx/DotNET.jl)

This package provides interoperability between Julia and [`Common Language Runtime`](https://docs.microsoft.com/dotnet/standard/clr), the execution engine of `.NET` applications. Many languages run on CLR, including `C#`, `Visual Basic .NET` and `PowerShell`.

⚠ This package is still a Work-In-Progress, its behaviors and public APIs may change dramatically.

## Prerequisites

You will need to have `.NET Core` SDK/runtime 2.0 or higher installed on the machine ([Download](https://dotnet.microsoft.com/download)). If the package fails to locate the runtime, set `DOTNET_ROOT` environment variable to the path containing the `dotnet` or `dotnet.exe` binary.

⚠ `.NET Framework` is currently not supported (but on the roadmap).

This package uses `Artifacts` to provide binary dependencies, so Julia 1.3+ is required.

## Installation

```julia
julia> using Pkg

julia> Pkg.add(PackageSpec(url="https://github.com/azurefx/DotNET.jl"))
```

## Usage

1. Use [`T"AssemblyQualifiedTypeName"`](https://docs.microsoft.com/dotnet/standard/assembly/find-fully-qualified-name) to address a type:

```julia
julia> Console=T"System.Console, mscorlib"
System.Console
```

2. Use `.` to access a member:

```julia
julia> Console.WriteLine("Hello, CLR!");
Hello, CLR!
```

3. Use reflection to load assemblies from file:

```julia
julia> T"System.Reflection.Assembly".LoadFrom(raw"C:\Users\Azure\Desktop\test.dll")
System.Reflection.RuntimeAssembly("test, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null")
```

4. To create an object:

```
julia> T"System.String".new('6',Int32(3))
"666"

julia> List=T"System.Collections.Generic.List`1"
System.Collections.Generic.List`1[T]

julia> List.new[T"System.Int64"]()
System.Collections.Generic.List`1[System.Int64]("System.Collections.Generic.List`1[System.Int64]")

```

5. To create delegates from Julia methods:

```
julia> list=List.new[T"System.Int64"](1:5);

julia> list.RemoveAll(delegate(iseven,T"System.Predicate`1[System.Int64]"))
2

julia> collect(list)
3-element Array{Int64,1}:
 1
 3
 5
```

## TODO

- Implicit conversions when calling CLR methods
- More operators
- `using` directive like C#
- Smart assembly/type resolution
- Configurable runtime versions
- Julia type system consistency
- .NET Framework support
- PowerShell support (maybe in another package)
