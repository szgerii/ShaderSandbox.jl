# ShaderSandbox.jl

This is a simple Julia program that can be used to experiment with fragment shaders, heavily inspired by [Íñigo Quílez](https://iquilezles.org/) and [Pol Jeremias](https://www.poljeremias.com/)'s [Shadertoy](https://shadertoy.com).

It has [GLSLTranspiler.jl](https://github.com/szgerii/GLSLTranspiler.jl) integrated, as the whole project was created to enable quick testing of shaders generated from Julia code.

## Installation

The tool has been implemented as a [Julia App](https://pkgdocs.julialang.org/v1/apps/), which means its installation is roughly the same as for any other package. Since it's not part of the General registry, it needs to be downloaded from GitHub:

In the Julia REPL, press `]` to enter Pkg mode, and run:
```bash
app add "https://github.com/szgerii/ShaderSandbox.jl"
```

This will download all necessary dependencies, and add `shader-sandbox` to your `.julia/bin` folder.
