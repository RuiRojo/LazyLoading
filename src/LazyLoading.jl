module LazyLoading

export @lazyinclude, @lazydepends, @once, @redirect, @copy_docs

include("Def.jl")

@def stripesc """
    stripesc(e::Expr)

Strip the external `:escape`s.
""" begin
    
    @test stripesc(:(2+2)) == :(2+2)
    @test stripesc(esc(esc(:(2+2)))) == :(2+2)
    
    end begin
stripesc(s::Symbol) = s
function stripesc(e::Expr)
    while e.head === :escape
        e = e.args[end]
    end

    return e
end
end


# Maybe better to use `which`
"""
    @method f(..) = ...

Define `f` but return the `Method` object.
It can also be used with `function`, but no docstrings. Don't get liberal with the 
formatting.
It requires that the new method is new and not a redefinition.
"""
macro method(fdef)

    fsig = fdef.args[1]
    f    = fsig.args[1]
    fesc = esc(f)    
    
    return quote
        mold = $(Expr(:isdefined, fesc)) ? methods($fesc) : Method[]
        $(esc(fdef))
        mnew = methods($fesc)
        
        first(setdiff(mnew, mold))
    end
end


# Prov. This doesn't work well with kwargs
delete_method(m::Method) = Base.delete_method(m)

@def signature_to_callback """
    signature_to_callback(s)

Turn the expr of the signature of a function (`f(x::Int)`)
into the expr of how to call it back `f(x)`
""" begin
    @test signature_to_callback(
        :(f(x1::Int, x2=9; y1::Int=3, y2=8, y3...))) ==
        :(f(x1, x2; y1=y1, y2=y2, y3...))
end begin
signature_to_callback(s; x...) = s
function signature_to_callback(e::Expr; inpar=false)
    h = e.head
    
    h == :call && return Expr(:call, signature_to_callback.(e.args)...)
        # Remove the type
    h == :(::) && return signature_to_callback(e.args[1])
    
    h == :parameters && return Expr(:parameters, 
        signature_to_callback.(e.args; inpar=true)...)
    
    h != :kw && return e
    
    # It's a kw
    lhs = signature_to_callback(e.args[1])
    
    return inpar ? Expr(:kw, lhs, lhs) : lhs
        
end
end

"""
    once(signatures..., code)

Set up definitions for `sigiatures` that run `code` only the first time
they are called. The methods are deleted as soon as entering.
The functions are run at local scope, and can reference the variables 
in the signature. The code can use the function `_recurse()` to run 
the same function with the same arguments provided. This is meant for the
use case where you redefine the function while in the body. 

Currently does not delete the definition with kwarg signatures. 
It 
"""
macro once(args...)
    @assert length(args) >= 2
 
    code = last(args)
    signatures = args[1:end-1]

        # vector of code for all function definitions that get added to `methods`
    funs :: NTuple{N, Expr} where N = map(signatures) do s
        lhscode = Expr(:call, esc(s.args[1]), esc.(s.args[2:end])...)
        rhscode = quote

            $(esc(:_recurse))() = $(esc(invokelatestify(signature_to_callback(s))))            

            @eval $s = error("Method no longer defined")
            Base.delete_method.(mets)

            $(esc(code))
        end
        fundefcode = :($lhscode = $rhscode)

        :(push!(mets, @method($fundefcode)))
    end 

    funscode = Expr(:block, funs...)
    
    fullcode = quote
        mets = Method[]
        $funscode
        nothing
    end

    return fullcode
end


@def invokelatestify """
    invokelatestify(e)

Turn an expression for the call to a function `f(x)` into
the expression for call through `Base.invokelatest`
(`Base.invokelatest(f, x)`)
""" begin
    @test invokelatestify(:(f(x)))      == :(Base.invokelatest(f, x))
    @test invokelatestify(:(f(x=0)))    == :(Base.invokelatest(f, x=0))
    @test invokelatestify(:(f(x; y=0))) == :(Base.invokelatest(f, x; y=0))
    end ->
function invokelatestify(e::Expr)
    @assert e.head ==  :call
    
    haspars(e::Expr) = begin 
        a = e.args
        
        return  length(a) >=2 && 
                a[2] isa Expr && 
                a[2].head == :parameters
    end
    
    if haspars(e)
        Expr(:call, :(Base.invokelatest), e.args[2], e.args[1], e.args[3:end]...)
    else
        :(Base.invokelatest($(e.args...)))
    end
end

@def untype """
    untype(expr)

Remove the type information from the expression `expr`, 
    skipping possible varargs `:...`.
""" begin
    @test untype(:x) == :x
    @test untype(:(x::Int)) == :x
    @test untype(:(x::Int...)) == :(x...)
end begin 
untype(s::Symbol) = s
function untype(arg::Expr)
    arg.head == :(::) ? 
        arg.args[1] : 
        Expr(arg.head, untype.(arg.args)...)
end
end




@def funapp """
    funapp(sig::Expr)

Transform the function signature `sig` into the function application 
without type annotations
""" begin
    @test funapp(:(f(x::Int))) == :(f(x))

            # not sure why, it seems like an old patch
    @test funapp(esc(:(f(x::Int)))) == :(f(x))
        # should work for, at least, the most general varargs
    @test funapp(:(f(x...; y...))) == :(f(x...; y...))
    @test funapp(:(f(x...))) == :(f(x...))
    end ->
function funapp(sig::Expr) 
    sig = stripesc(sig)
    fun = sig.args[1]
    args = sig.args[2:end]
    
    
    untyped_args = untype.(args)

    
    Expr(:call, fun, untyped_args...)
end



@def getfundef """
    getfundef(x::Expr)

Strip the outer boilerplate until a `:=` or `:function` is reached
""" begin
    @test getfundef(:(begin; f(x) = x^2; end)) == :(f(x) = x^2)
    end ->
getfundef(x::Expr) = begin 
    while x.head !== :(=) && x.head !== :function
        x = x.args[end]
    end
    return x
end

@def getsignature """
    getsignature(funcode::Expr)

Extracts the signature of the function code.
""" begin
    @test getsignature(:(f(x) = x)) == :(f(x))
    @test getsignature(esc(:(f(x) = x))) == :(f(x))
    end ->
function getsignature(funcode::Expr) 
    fundef = getfundef(funcode)
    
    return fundef.args[1]
end


"""
    @lazydepends Pkg1 Pkg2 ->
    function lala(x)
        [...]
    end

Define the function to preload packages on first use.
"""
macro lazydepends(args...)
    @assert length(args) >= 1

    #argument parsing
    pkgs, fundefcode = let lastpkg, pkgfun
       pkgfun  = last(args) 
       lastpkg = pkgfun.args[1] 
     
        [args[1:end-1]..., lastpkg], getfundef(pkgfun.args[end])
    end
    dottedpkgs = map(p -> Expr(:., p), pkgs)    
    usingcode  = Expr(:using, dottedpkgs...)
    usingcode  = :(@eval($usingcode))

            #function signature
    sig = getsignature(fundefcode)
    
    fundef_global = :(@eval $fundefcode)
    funapp_global = invokelatestify(funapp(sig))

    out = quote 
        @once $sig begin
            $usingcode
            $fundef_global           
            $funapp_global
        end
    end |> esc

    return out
end


@def setsignature """
    setsignature(head::Symbol, args::Vector)

Builds the expression for the function signature.
""" begin
    @test setsignature(:f, [:(x::Any)]) == :(f(x::Any))
    @test setsignature(:f, [:(x::Int)], [:h]) == :(f(x::Int; h))
    end begin
setsignature(head, arg) = :($head($(arg...)))
setsignature(head, arg, par) = :($head($(arg...); $(par...)))
end


#=
This won't work for symbols that are imported with `using` so come
from other modules, because it will be in conflict with the local
symbols previously introduced for the catch-all loading definition.
In these cases, one should manually add a catch-all definition.
I think the dosctrings will be lost. 

Sigh...

    The macro `@link` does this.
=#
"""
Set `fn` for inclusion the first time any `sym` is called.
After loading the file, then call the function.
"""
macro lazyinclude(fn, sym1, syms...)
    syms = [sym1, syms...]
    signatures = map(s->setsignature(s, [:(x...)], [:(y...)]), syms) 
 
    return quote        
        @once $(signatures...) begin 
 
            lazyinclude($fn)
            _recurse()
        end
        
    end |> esc
end
 
"""
Create catch-all definitions that link to the specified module
"""
macro redirect(mod, syms...)
    return Expr(:block, (
        begin
            symparent = :(getproperty($mod, $(Meta.quot(sym))))
            quote
                $sym(x...; y...) = $symparent(x...; y...)
#                @doc (@doc $symparent) $sym
                nothing
            end
        end for sym ∈ syms
    )...) |> esc
end

"""
    @copy_docs Module sym1 [sym2...]
    
Copy the docs from symbols `sym1`, etc of module `Module` to the current ones
"""
macro copy_docs(mod, syms...)
    return Expr(:block, (
        begin
            symparent = :(getproperty($mod, $(Meta.quot(sym))))
            quote
                @doc (@doc $symparent) $sym
            end
        end for sym ∈ syms 
    )...) |> esc
end


end # module
