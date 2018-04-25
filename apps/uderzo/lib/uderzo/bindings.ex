defmodule Uderzo.Bindings do
  @moduledoc """
  Uderzo Elixir->C bindings in Clixir. Note that for demo purposes, 
  this is a hodgepodge of various modules - NanoVG, GLFW, utility
  methods, demo methods; there's nothing however that precludes
  a clean separation.
  """
  use Uderzo.Clixir

  @clixir_target "c_src/uderzo"

  defgfx comment(comment) do
    cdecl "char *": comment
    fprintf(stderr, "Got comment [%s]", comment)
  end

  # GLFW code

  defgfx glfw_create_window(width, height, title, pid) do
    cdecl "char *": title
    cdecl long: [length, width, height]
    cdecl erlang_pid: pid
    cdecl "GLFWwindow *": window
    window = glfwCreateWindow(width, height, title, NULL, NULL)

    # There is certain stuff that only can be done when we have a GLFW window. 
    # Do that now. 

    glfwMakeContextCurrent(window)
    glfwSwapInterval(0)
    if vg == NULL do
      vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
      assert(vg != NULL)
      loadDemoData(vg, &data) # TODO hardcoding demo data in a library... bad.
    end
    if window != NULL do
      {pid, {:glfw_create_window_result, window}}
    else
      # TODO this is sent as an atom instead of a binary.
      {pid, {:error, "Could not create window"}}
    end
  end

  defgfx glfw_destroy_window(window) do
    cdecl "GLFWwindow *": window
    glfwDestroyWindow(window)
  end

  # Utility code

  # This stuff should be done every frame. It's simpler if we do it here than pass
  # a bunch of messages up and down. When it's ready, a message is sent back that
  # can kick off the actual drawing. Most of this code lifted straight from the
  # NVG Demo.
  defgfx uderzo_start_frame(window, pid) do
    cdecl "GLFWwindow *": window
    cdecl erlang_pid: pid
    cdecl int: [winWidth, winHeight, fbWidth, fbHeight]
    cdecl double: [mx, my, t, pxRatio]

    glfwGetCursorPos(window, &mx, &my)
    glfwGetWindowSize(window, &winWidth, &winHeight)
    glfwGetFramebufferSize(window, &fbWidth, &fbHeight)
    # Calculate pixel ration for hi-dpi devices.
    pxRatio = fbWidth / winWidth

    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)
    glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_CULL_FACE)
    glDisable(GL_DEPTH_TEST)

    nvgBeginFrame(vg, winWidth, winHeight, pxRatio)

    {pid, {:uderzo_start_frame_result, mx, my, winWidth, winHeight}}
  end

  defgfx uderzo_end_frame(window, pid) do
    cdecl "GLFWwindow *": window
    cdecl erlang_pid: pid

    nvgEndFrame(vg)
    glEnable(GL_DEPTH_TEST)

    glfwSwapBuffers(window)
    glfwPollEvents()

    {pid, :uderzo_end_frame_done}
  end

  # Demo code. These are some very high level calls basically just to get
  # some eyecandy going. Ideally, all the NanoVG primitives would be mapped.

  defgfx demo_render(mx, my, width, height, t) do
    cdecl double: [mx, my, width, height, t]

    renderDemo(vg, mx, my, width, height, t, 0, &data)
  end
end

#  LocalWords:  GLFWwindow
