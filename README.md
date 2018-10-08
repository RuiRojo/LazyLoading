# LazyLoading.jl

This is very much a WIP that I had sketched for personal use and learning about macros.

Needs to be documented, tested, improved, etc etc


# `@lazydepends`

Define the function to preload packages on first use.


```julia
@lazydepends Pkg1 Pkg2 ->
function lala(x)
    [...]
end
```

This defined `lala(x)` in such a way that it can use stuff from `Pkg1` or `Pkg2`, but
only runs `using Pkg1` and `using Pkg2` on the first use of `lala(x)`.

## Example



# `@lazyinclude`

```julia
@lazyinclude "path/to/script.jl" sym1 sym2
```

Creates catch-all methods for `sym1`, `sym2`, etc, that include "path/to/script.jl".

It is assumed that `sym1`, `sym2` are defined in that script, so the catch-all definitions
are removed, and the new definitions are called.


# `@redirect`


# `@once`

# `@copy_docs`

```julia    
    @copy_docs Module sym1 sym2    
```

Copy the docs from symbols `sym1`, `sym2`, etc of module `Module` to the symbols in the current context.

# `@def`

This macro doesn't have anything to do with the package, but I use it, and it's here, so it's exported.

It's just a macro to force good habits and make it easier to test internal functions.

```julia
@def wash """
    wash(shirt::Int)

Do the washing up.
""" begin
    @test wash(3) == "Clean"
    @test wash(4) == "Still dirty"
    @test wash(10) == "Blergh"
end function wash(shirt::Int)
    shirt < 4 && return "Clean"
    shirt < 8 && return "Still dirty"
    return "Blerg"
end

This defines `wash` and its docs. Furthermore, if `capture_tests(true)` was run before this code,
also those tests were stored.

`@inline_testall` tests all the functions for the current module.

`@inline_testall Mod` tests all the functions for module `Mod`

`@inline_test f` tests the function `f`
```

@lazyinclude, @lazydepends, @once, @redirect, @copy_docs

@lazyinclude joinpath(@__DIR__, "Plot.jl") plot plot! default surf imagesc histogram heatmap specplot zplane scatter stem vline
@copy_docs Plots plot plot! surf imagesc histogram heatmap scatter vline default
export plot, plot!, surf, imagesc, histogram, heatmap, specplot, zplane, scatter, stem, vline, default


and in "Plot.jl", @redirect Plots plot plot! surf imagesc histogram heatmap scatter vline default
