struct WindowInfo
    x_pos::Int
    y_pos::Int
    width::Int
    height::Int
end

function init_window(width, height)
    window = GLFW.CreateWindow(width, height, "Shader Sandbox")
    GLFW.MakeContextCurrent(window)
    GLFW.SetWindowSize(window, width, height)

    glViewport(0, 0, width, height)

    return window
end

function getDPIScale()
    monitor = GLFW.GetPrimaryMonitor()
    # assumes x and y scale are identical
    scale = GLFW.GetMonitorContentScale(monitor).xscale
    scale
end

function initCImGui(window)
    CImGui.CreateContext()

    CImGui.StyleColorsDark()
    CImGui.ImGui_ImplGlfw_InitForOpenGL(window.handle, true)
    CImGui.ImGui_ImplOpenGL3_Init("#version 330")

    # set dpi scaling for ImGui
    scale = getDPIScale()
    style_ptr = Ptr{CImGui.ImGuiStyle}(CImGui.GetStyle())
    style_ptr.FontScaleDpi = scale
    CImGui.ScaleAllSizes(style_ptr, scale)
end