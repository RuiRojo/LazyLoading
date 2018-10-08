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



@lazyinclude, @lazydepends, @once, @redirect, @copy_docs

@lazyinclude joinpath(@__DIR__, "Plot.jl") plot plot! default surf imagesc histogram heatmap specplot zplane scatter stem vline
@copy_docs Plots plot plot! surf imagesc histogram heatmap scatter vline default
export plot, plot!, surf, imagesc, histogram, heatmap, specplot, zplane, scatter, stem, vline, default


and in "Plot.jl", @redirect Plots plot plot! surf imagesc histogram heatmap scatter vline default
