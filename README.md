# ShaderSandbox.jl

This is a simple Julia program that can be used to experiment with fragment shaders, heavily inspired by [Íñigo Quílez](https://iquilezles.org/) and [Pol Jeremias](https://www.poljeremias.com/)'s [Shadertoy](https://shadertoy.com).

It has [GLSLTranspiler.jl](https://github.com/szgerii/GLSLTranspiler.jl) integration, since the whole project was created to enable quick testing of shaders generated from Julia code.

<img width="1920" height="1032" alt="Screenshot of the app displaying a demonstration of a circle's SDF." src="https://github.com/user-attachments/assets/3ea98987-ae51-4104-bf57-84b0e77a55a6" />

The shader in the screenshot comes (once again) from Íñigo Quílez and is available [here](https://www.shadertoy.com/view/3ltSW2). It has been transpiled to a Julia "shader" by hand and programatically transpiled back to GLSL using the transpiler mentioned above. The shader itself is a demonstration of a circle's signed distance function.

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
