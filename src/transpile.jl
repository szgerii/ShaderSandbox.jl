function handle_transpile(jl_code::String)::Union{String,Nothing}
    frag_code = missing

    try
        expr = Meta.parse("begin $jl_code end")

        isnothing(expr) && return nothing

        if Meta.isexpr(expr, :error) || Meta.isexpr(expr, :incomplete)
            println(stderr, "Julia syntax error in '$path':")
            dump(stderr, expr)
            return nothing
        end

        run_benchmarks = "--transpiler-benchmarks" in ARGS
        frag_code = transpile(expr; run_benchmarks, throw_error=true)

        isempty(frag_code) && return nothing

        return frag_code
    catch err
        showerror(stderr, err)
        return nothing
    end
end

