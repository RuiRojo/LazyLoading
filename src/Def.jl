export capture_tests, @def, @inline_test, @inline_testall, @test, @testset, Test


"Tests the function `f` for which tests were defined through `@def`"
macro inline_test(mod, f)
 
    return quote
        let tfun
            if isdefined($mod, :TESTS)
                tfun =  get($mod.TESTS, f) do 
                    error("Test for $f not defined")
                end
                tfun()
            else
                error("Test for $f not defined")
            end
        end
    end |> esc
end
macro inline_test(f)
    :(@inline_test $__module__ f) |> esc 
end


"Tests all the functions for which tests are defined through `@def`"
macro inline_testall(mod)

    return quote
        if isdefined($mod, :TESTS)
            for fun in values($mod.TESTS); fun(); end
        end
    end |> esc
end
macro inline_testall()
    :(@inline_testall $__module__) |> esc
end


CAPTURE_TESTS = false
capture_tests() = CAPTURE_TESTS
capture_tests(b::Bool) = (global CAPTURE_TESTS = b)


macro def(fname, docstr, rest)
# rest contains testcode -> code

    testcode, code = rest.args

    return def(fname, docstr, testcode, code)
end

macro def(fname, docstr, testcode, code)
    return def(fname, docstr, testcode, code)
end



function def(fname, docstr, testcode, code)
    fnameStr = string(fname)
    fesc = Expr(:escape, fname)
    testset =  quote
        @testset $fnameStr begin
            $testcode
        end
    end

    CAPTURE_TESTS || return quote
        $(esc(code))
        @doc $docstr $fname
    end


    esctest = esc(:TESTS)
    return  quote
        @clearfun $fname
        global $esctest
        $(esc(:(@isdefined TESTS))) || ($esctest = Dict{Function, Function}())
        $(esc(code))        
        tfun() = let; $(esc(testset)); end
        push!($(esc(:TESTS)), $fesc => tfun)
        @doc $docstr $fname
        nothing
    end
end
