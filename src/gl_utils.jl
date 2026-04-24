function ul(prog::GLuint, name::String)
    glGetUniformLocation(prog, name)
end

function genOne(glFunc)
    id = Ref{GLuint}(0)
    glFunc(1, id)
    id[]
end

function checkErrors(msg_suffix::String)
    err = glGetError()
    if err != GL_NO_ERROR
        println("OpenGL error(s) occured $msg_suffix")
    end

    while err != GL_NO_ERROR
        println(err)

        err = glGetError()
    end
end

function compileShader(source, type)::Union{GLuint,Nothing}
    shader = glCreateShader(type)::GLuint

    glShaderSource(shader, 1, Ref(pointer(source)), C_NULL)
    glCompileShader(shader)

    success = Ref{GLint}(0)
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)

    if success[] == GL_FALSE
        log_len = Ref{GLint}(0)
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, log_len)

        log = Vector{UInt8}(undef, log_len[])
        glGetShaderInfoLog(shader, log_len[], log_len, log)

        println("\nError while compiling shaders, see below for a detailed error message:")
        println(String(log))

        glDeleteShader(shader)

        return nothing
    end

    shader
end

function updateShaders(prev_prog, vs_path::Vector{Cchar}, fs_path::Vector{Cchar})
    vsh = read(unsafe_string(pointer(vs_path)), String)
    fsh = read(unsafe_string(pointer(fs_path)), String)

    compiledVSH = compileShader(vsh, GL_VERTEX_SHADER)
    compiledFSH = compileShader(fsh, GL_FRAGMENT_SHADER)

    if isnothing(compiledVSH) || isnothing(compiledFSH)
        return nothing
    end

    if prev_prog != -1
        glDeleteProgram(prev_prog)
    end

    prog = glCreateProgram()
    glAttachShader(prog, compiledVSH)
    glAttachShader(prog, compiledFSH)
    glLinkProgram(prog)

    glUseProgram(prog)

    return prog
end

updateShaders(vs_path, fs_path) = updateShaders(-1, vs_path, fs_path)
