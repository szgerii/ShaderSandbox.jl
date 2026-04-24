# ShaderSandbox.jl

This is a simple Julia program that can be used to experiment with fragment shaders, heavily inspired by [Íñigo Quílez](https://iquilezles.org/) and [Pol Jeremias](https://www.poljeremias.com/)'s [Shadertoy](https://shadertoy.com).

It has [GLSLTranspiler.jl](https://github.com/szgerii/GLSLTranspiler.jl) integrated, as the whole project was created to enable quick testing of shaders generated from Julia code.

## Installation

The tool has been implemented as a [Julia App](https://pkgdocs.julialang.org/v1/apps/), which means its installation is roughly the same as for any other package. Since it's not part of the General registry, it needs to be downloaded from GitHub.

### Option 1 (as a standalone application)

In the Julia REPL, press `]` to enter Pkg mode, and run:
```bash
(@myjuliaversion) pkg> app add "https://github.com/szgerii/ShaderSandbox.jl"
```

This will download all necessary dependencies, and add a script that starts the app, named `shader-sandbox` to your `~/.julia/bin` folder.

Afterwards, if you have `~/.julia/bin` in your PATH, the app can be started from anywhere by running:
```bash
myuser@mymachine:~$ shader-sandbox
```

### Option 2 (as a Pkg)

It's also possible to simply clone the repo and manually start the app as a regular Julia script. Note that this requires instantiating the pkg first.

Example installation:
```bash
myuser@mymachine:~$ git clone "https://github.com/szgerii/ShaderSandbox.jl"
myuser@mymachine:~$ cd ShaderSandbox.jl
myuser@mymachine:~/ShaderSandbox.jl$ julia
julia> using Pkg
julia> Pkg.activate(".")
julia> Pkg.instantiate()
```

These only need to be executed once after cloning. Afterwards, the app can be simply started with:
```bash
myuser@mymachine:~/ShaderSandbox.jl$ julia --project=. src/run.jl
```
