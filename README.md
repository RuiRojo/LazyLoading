# LazyLoading.jl

This is very much a WIP that I had sketched for personal use and learning about macros.

Needs to be documented, tested, improved, etc etc. I wouldn't be surprised if its functionality is unnecessary or superseeded by other packages.

## Functions

### `@lazydepends`

Define the function to preload packages on first use.


```julia
@lazydepends Plots Plits ->
function plah(x)
    plot(sin, 0, x, xlims = Plits.yeye)
end
```

This defines `plah(x)` in such a way that it can use stuff from `Plots` and `Plits`, but
only runs `using Plots` and `using Plits` on the first use of `plah(x)`.

#### Example



### `@lazyinclude`

```julia
@lazyinclude "path/to/script.jl" sym1 sym2
```

Creates catch-all methods for `sym1`, `sym2`, etc, that include "path/to/script.jl".

It is assumed that `sym1`, `sym2` are defined in that script, so the catch-all definitions
are removed, and the new definitions are called.


### `@redirect`

Create catch-all definitions that link to the specified module

```julia
@redirect Plots plot surf
```

This creates definitions for `plot` and `surf` that redirect its arguments to `Plots.plot` and `Plots.surf`.


### `@once`

```julia
@once f(::Int) f(x, y) begin
    println("First")
end
```


Set up definitions for `f(::Int)` and `f(x, y)` that run the specified only the first time
ANY of these methods are called. Both methods are deleted as soon as entering.


The code can use the function `_recurse()` to run 
the same function with the same arguments provided. This is meant for the
use case where you redefine the function while in the body. `_recurse()` uses
`Base.invokelatest`.


### `@copy_docs`

```julia    
    @copy_docs Module sym1 sym2    
```

Copy the docs from symbols `sym1`, `sym2`, etc of module `Module` to the symbols in the current context.

### `@def`

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
```

This defines `wash` and its docs. Furthermore, if `capture_tests(true)` was run before this code,
also those tests were stored.

`@inline_testall` tests all the functions for the current module.

`@inline_testall Mod` tests all the functions for module `Mod`

`@inline_test f` tests the function `f`

### `@clearfun`

`@clearfun f` clears the methods for `f`.

## Usage example

Say you have a package "Pkg.jl" that needs "Plots.jl" his plotting functions, but it is often the case
that the user doesn't need to plot anything, and "Plots.jl" for some reason takes too long to load.

You could have a separate file "Plotting.jl" with all the plotting functionality is implemented.

Then, in "Pkg.jl"

```julia
@lazyinclude joinpath(@__DIR__, "Plotting.jl") plot_this plot surf
@copy_docs Plots plot surf
```

The first line defines `plot_this`, `plot` and `surf`, to include "Plotting.jl" on first usage and then re-run. 

I don't remember whether the explicit `@__DIR__` is necessary. It seems at some point it was.

The second line adds the docs of `Plots.plot` and `Plots.surf` to the local symbols.

Then, on "Plotting.jl"

```
export plot_this, plot, surf

@redirect Plots plot surf

function plot_this(x)
    println(x)
    return """
                        `. ___
                        __,' __`.                _..----....____
            __...--.'``;.   ,.   ;``--..__     .'    ,-._    _.-'
    _..-''-------'   `'   `'   `'     O ``-''._   (,;') _,'
    ,'________________                          \`-._`-','
    `._              ```````````------...___   '-.._'-:
        ```--.._      ,.                     ````--...__\-.
                `.--. `-`                       ____    |  |`
                `. `.                       ,'`````.  ;  ;`
                    `._`.        __________   `.      \'__/`
                    `-:._____/______/___/____`.     \  `
                                |       `._    `.    \
                                `._________`-.   `.   `.___
                                                SSt  `------'`
    """
```

The `@redirect` line creates the final definitions of `plot` and `surf` that will delegate to `Plots.plot` and `Plots.surf`.
