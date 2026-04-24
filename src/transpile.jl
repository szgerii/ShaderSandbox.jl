module TranspilerWrapper

using GLSLTranspiler
using GLSLTranspiler.GLSL
using JuliaGLM

function handle_transpile(jl_code::String)::Union{String,Nothing}
    frag_code = missing

    try
        parsed = Meta.parse(jl_code)

        parsed = macroexpand(@__MODULE__, parsed, recursive=true)
        (_, frag_code) = GLSLTranspiler.run_pipeline(GLSLTranspiler.GLSL.GLSLPipeline, parsed, @__MODULE__)

        return frag_code
    catch err
        println("An error occured during code transpilation:")
        println(err)

        return nothing
    end
end

export handle_transpile

end
