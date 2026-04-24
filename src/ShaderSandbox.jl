module ShaderSandbox

const TRANSPILE_OUTPUT_PATH = "./shaders/transpiled.frag"

const INITIAL_VS_PATH = "./shaders/full_screen.vert"
const INITIAL_FS_PATH = "./shaders/shadertoy.frag"

const JULIA_CODE_MAX_LEN = 4096 * 4

using Dates
import GLFW
using ModernGL
using CImGui

include("AverageQueue.jl")
include("gl_utils.jl")
include("gui.jl")
include("transpile.jl")

using .TranspilerWrapper

function (@main)(ARGS)
    gen_glsl_code = ""

    vs_path_buf = Vector{Cchar}(undef, 128)
    setindex!(vs_path_buf, Vector{Char}(INITIAL_VS_PATH), 1:length(INITIAL_VS_PATH))
    vs_path_buf[length(INITIAL_VS_PATH)+1] = '\0'

    fs_path_buf = Vector{Cchar}(undef, 128)
    setindex!(fs_path_buf, Vector{Char}(INITIAL_FS_PATH), 1:length(INITIAL_FS_PATH))
    fs_path_buf[length(INITIAL_FS_PATH)+1] = '\0'

    julia_code_buf = Vector{Cchar}(undef, JULIA_CODE_MAX_LEN)
    julia_code_buf[1] = '\0'

    width = 1200
    height = 1200

    window = init_window(width, height)

    prog = updateShaders(vs_path_buf, fs_path_buf)

    if isnothing(prog)
        error("couldn't compile initial shaders")
    end

    playing = true
    advance = false

    last_win::Union{WindowInfo,Nothing} = nothing

    function handleKeyEvent(win, key, scancode, action, mods)
        if action == GLFW.PRESS
            if key == GLFW.KEY_SPACE
                playing = !playing
            end

            if key == GLFW.KEY_L
                advance = true
            end

            if key == GLFW.KEY_F5 && (mods & GLFW.MOD_CONTROL) != 0
                new_prog = updateShaders(prog, vs_path_buf, fs_path_buf)
                if !isnothing(new_prog)
                    prog = new_prog
                end
            end

            if key == GLFW.KEY_F11
                win_monitor = GLFW.GetWindowMonitor(window)

                if win_monitor.handle == C_NULL
                    # save windowed settings and switch to monitor's full screen settings
                    w_pos = GLFW.GetWindowPos(window)
                    w_size = GLFW.GetWindowSize(window)
                    last_win = WindowInfo(w_pos[1], w_pos[2], w_size[1], w_size[2])

                    prim_monitor = GLFW.GetPrimaryMonitor()
                    mode = GLFW.GetVideoMode(prim_monitor)
                    GLFW.SetWindowMonitor(window, prim_monitor, 0, 0, mode.width, mode.height, mode.refreshrate)
                else
                    # revert previous (or default) windowed state
                    if isnothing(last_win)
                        last_win = WindowInfo(100, 100, 600, 600)
                    end

                    GLFW.SetWindowMonitor(window, GLFW.Monitor(C_NULL), last_win.x_pos, last_win.y_pos, last_win.width, last_win.height, 0)
                end
            end
        end
    end

    GLFW.SetKeyCallback(window, handleKeyEvent)

    function handleWindowResize(window, new_width, new_height)
        width = convert(Int, new_width)
        height = convert(Int, new_height)

        glViewport(0, 0, width, height)
    end

    GLFW.SetWindowSizeCallback(window, handleWindowResize)

    mouse_btn_down = false

    function handleMouseClick(window, btn, action, mods)
        if btn == GLFW.MOUSE_BUTTON_LEFT
            mouse_btn_down = action == GLFW.PRESS
        end
    end

    GLFW.SetMouseButtonCallback(window, handleMouseClick)

    initCImGui(window)

    last_active = now()
    time_acc::Float32 = 0

    fps_counter = AverageQueue{Float32}(50)

    prev_mouse_state = mouse_btn_down
    mouse_uniform = GLfloat[0, 0, 0, 0]

    # enable vsync by default
    vsync_enabled = Ref{Bool}(true)
    GLFW.SwapInterval(1)

    vert_count = Ref{GLint}(6)

    is_dragging_shader = false

    glClearColor(0.4, 0.6, 0.95, 1.0)
    while !GLFW.WindowShouldClose(window)
        time = now()
        time_passed_sec = Dates.value(time - last_active) / 1000

        delta_time = 0.0
        if playing
            delta_time = time_passed_sec
        elseif advance
            delta_time = 1.0 / 60.0
        end

        time_acc += delta_time

        last_active = time

        frame_time = 1 / delta_time
        isinf(frame_time) && (frame_time = 0)
        add!(fps_counter, frame_time)

        glUniform1f(ul(prog, "time"), time_acc)
        glUniform1f(ul(prog, "delta"), delta_time)

        year = Dates.year(time)
        month = Dates.month(time)
        day = Dates.day(time)
        date = GLint[year, month, day]
        glUniform3iv(ul(prog, "date"), 1, pointer(date))

        res_data = GLint[width, height]
        glUniform2iv(ul(prog, "resolution"), 1, pointer(res_data))

        CImGui.ImGui_ImplOpenGL3_NewFrame()
        CImGui.ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        just_clicked = mouse_btn_down && !prev_mouse_state
        io = CImGui.GetIO()

        if just_clicked
            is_dragging_shader = !unsafe_load(io.WantCaptureMouse)
        elseif !mouse_btn_down
            is_dragging_shader = false
        end

        if is_dragging_shader
            cpos = GLFW.GetCursorPos(window)

            cpos = [clamp(cpos.x, 0, width), clamp(height - cpos.y, 0, height)]

            mouse_uniform[1:2] = [cpos...]

            if just_clicked
                mouse_uniform[3:4] = [cpos...]
            end
        else
            mouse_uniform[3] = -abs(mouse_uniform[3])
        end

        if !just_clicked || !is_dragging_shader
            mouse_uniform[4] = -abs(mouse_uniform[4])
        end

        prev_mouse_state = mouse_btn_down

        glUniform4fv(ul(prog, "mouse"), 1, pointer(mouse_uniform))

        checkErrors("pre-draw")

        glClear(GL_COLOR_BUFFER_BIT)
        glDrawArrays(GL_TRIANGLES, 0, vert_count.x)

        checkErrors("during draw")

        CImGui.SetNextWindowSizeConstraints(CImGui.ImVec2(width, div(height, 4)), CImGui.ImVec2(width, height))
        CImGui.SetNextWindowPos((0, 0))

        CImGui.Begin("Menu", C_NULL)

        if CImGui.BeginTabBar("Menu Bar")
            if CImGui.BeginTabItem("Playback")
                CImGui.Text("Controls:")

                if CImGui.Button("Play/Pause")
                    playing = !playing
                end

                CImGui.SameLine()
                CImGui.Spacing()
                CImGui.SameLine()

                if CImGui.Button("Advance")
                    advance = true
                end

                CImGui.SameLine()
                CImGui.Spacing()
                CImGui.SameLine()

                if CImGui.Button("Reset")
                    time_acc = 0
                end

                CImGui.NewLine()

                CImGui.Text("Settings:")

                if CImGui.Checkbox("Enable V-Sync", vsync_enabled)
                    if vsync_enabled.x
                        GLFW.SwapInterval(1)
                    else
                        GLFW.SwapInterval(0)
                    end
                end

                CImGui.EndTabItem()
            end

            if CImGui.BeginTabItem("Shaders")
                CImGui.Text("Vertex Shader Path")
                CImGui.InputText("##Vertex Shader Path", vs_path_buf, 100)
                CImGui.Text("Fragment Shader Path")
                CImGui.InputText("##Fragment Shader Path", fs_path_buf, 100)

                CImGui.Text("Recompile shaders:")
                CImGui.SameLine()
                if CImGui.Button("Recompile")
                    new_prog = updateShaders(prog, vs_path_buf, fs_path_buf)
                    if !isnothing(new_prog)
                        prog = new_prog
                    end
                    CImGui.SetWindowCollapsed("Menu", true)
                end

                CImGui.NewLine()

                CImGui.Text("Vertex Count:")
                CImGui.InputInt("##Vertex Count", vert_count, 1, 1)

                CImGui.EndTabItem()
            end

            if CImGui.BeginTabItem("Properties")
                CImGui.Text("FPS: " * string(round(avg(fps_counter))))
                CImGui.Text("Resolution: $width x $height")
                CImGui.Text("Status: " * (playing ? "Playing" : "Paused"))
                CImGui.Text("Mouse: (" * join(mouse_uniform, ",") * ")")
                CImGui.Text("Time: $time_acc")
                CImGui.Text("Delta: $delta_time")

                CImGui.EndTabItem()
            end

            if CImGui.BeginTabItem("Uniforms")
                sep = "\n\t\t"
                CImGui.Text("resolution: ivec2" * sep * "The resolution of the OpenGL viewport (in pixels)")
                CImGui.Text("time: float" * sep * "The elapsed time (in seconds) since the start of the current shader")
                CImGui.Text("delta: float" * sep * "The elapsed time (in seconds) since the last frame")
                CImGui.Text("mouse: vec2" * sep * "The current mouse position (in GLFW screen coordinates)")
                CImGui.Text("date: ivec3" * sep * "(year, month, day)")

                CImGui.EndTabItem()
            end

            if CImGui.BeginTabItem("Julia Transpiler")
                CImGui.Text("Enter Julia function definition to transpile:")
                CImGui.InputTextMultiline(
                    "##julia_code",
                    pointer(julia_code_buf),
                    JULIA_CODE_MAX_LEN,
                    (-CImGui.FLT_MIN, CImGui.GetTextLineHeight() * 32),
                )

                if CImGui.Button("Transpile")
                    frag_code = handle_transpile(unsafe_string(pointer(julia_code_buf)))

                    if (!isnothing(frag_code))
                        write(TRANSPILE_OUTPUT_PATH, frag_code)

                        zero(fs_path_buf)
                        setindex!(fs_path_buf, Vector{Char}(TRANSPILE_OUTPUT_PATH), 1:length(TRANSPILE_OUTPUT_PATH))
                        fs_path_buf[length(TRANSPILE_OUTPUT_PATH)+1] = '\0'

                        time_acc = 0
                        CImGui.SetWindowCollapsed("Menu", true)

                        new_prog = updateShaders(prog, vs_path_buf, fs_path_buf)
                        if !isnothing(new_prog)
                            prog = new_prog
                        end
                    end
                end


                CImGui.EndTabItem()
            end

            if !isempty(gen_glsl_code) && CImGui.BeginTabItem("Transpiled GLSL")
                CImGui.TextUnformatted(gen_glsl_code)

                CImGui.EndTabItem()
            end

            CImGui.EndTabBar()
        end

        CImGui.End()
        CImGui.Render()
        CImGui.ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()

        advance = false
    end

    GLFW.DestroyWindow(window)
    GLFW.Terminate()
end

end # module ShaderSandbox
